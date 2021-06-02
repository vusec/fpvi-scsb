/*
 * Enable user-mode ARM performance counter access.
 */
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/smp.h>

/** -- Configuration stuff ------------------------------------------------- */

#define DRVR_NAME "enable_arm_pmu"

#if !defined(__arm__) && !defined(__aarch64__)
#error Module can only be compiled on ARM machines.
#endif

/** -- Initialization & boilerplate ---------------------------------------- */
#define ARMV8_PMCR_MASK         0x3f
#define ARMV8_PMCR_E            (1 << 0) /*  Enable all counters */
#define ARMV8_PMCR_P            (1 << 1) /*  Reset all counters */
#define ARMV8_PMCR_C            (1 << 2) /*  Cycle counter reset */
#define ARMV8_PMCR_D            (1 << 3) /*  CCNT counts every 64th cpu cycle */
#define ARMV8_PMCR_X            (1 << 4) /*  Export to ETM */
#define ARMV8_PMCR_DP           (1 << 5) /*  Disable CCNT if non-invasive debug*/
#define ARMV8_PMCR_N_SHIFT      11       /*  Number of counters supported */
#define ARMV8_PMCR_N_MASK       0x1f

#define ARMV8_PMUSERENR_EN_EL0  (1 << 0) /*  EL0 access enable */
#define ARMV8_PMUSERENR_CR      (1 << 2) /*  Cycle counter read enable */
#define ARMV8_PMUSERENR_ER      (1 << 3) /*  Event counter read enable */

#define ARMV8_PMCNTENSET_EL0_ENABLE (1<<31) /* *< Enable Perf count reg */

#define PERF_DEF_OPTS (1 | 16)
#define PERF_OPT_RESET_CYCLES (2 | 4)
#define PERF_OPT_DIV64 (8)

static void
enable_cpu_counters(void* data)
{
	uint64_t val=0;

    printk(KERN_INFO "[" DRVR_NAME "] enabling user-mode PMU access on CPU #%d\n",
            smp_processor_id());

    
	asm volatile("mrs %0, id_aa64dfr0_el1" : "=r" (val));
    printk("%llx\n", val);

    /*  Enable user-mode access to counters. */
    isb();
    asm volatile("msr pmuserenr_el0, %0" : : "r"((u64)ARMV8_PMUSERENR_EN_EL0));
    isb();
	asm volatile("mrs %0, pmuserenr_el0" : "=r" (val));
    printk("%llx\n", val);

    /*   Performance Monitors Count Enable Set register bit 30:0 disable, 31 enable. Can also enable other event counters here. */
    asm volatile("msr pmcntenset_el0, %0" : : "r" (ARMV8_PMCNTENSET_EL0_ENABLE));

    /* Enable counters */
    val = 0;
    asm volatile("mrs %0, pmcr_el0" : "=r" (val));
    asm volatile("msr pmcr_el0, %0" : : "r" (val|ARMV8_PMCR_E));
}

static void
disable_cpu_counters(void* data)
{
    printk(KERN_INFO "[" DRVR_NAME "] disabling user-mode PMU access on CPU #%d",
            smp_processor_id());

    /*  disable user-mode access to counters. */
    isb();
    asm volatile("msr pmuserenr_el0, %0" : : "r"((u64)0));
    isb();
}

static int __init
init(void)
{
        on_each_cpu(enable_cpu_counters, NULL, 1);
        printk(KERN_INFO "[" DRVR_NAME "] initialized");
        return 0;
}

static void __exit
fini(void)
{
        on_each_cpu(disable_cpu_counters, NULL, 1);
        printk(KERN_INFO "[" DRVR_NAME "] unloaded");
}

MODULE_AUTHOR("Austin Seipp <aseipp@pobox.com>");
MODULE_LICENSE("Dual MIT/GPL");
MODULE_DESCRIPTION("Enables user-mode access to ARMv8 PMU counters");
MODULE_VERSION("0:0.1-dev");
module_init(init);
module_exit(fini);

