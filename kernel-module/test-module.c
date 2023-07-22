#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/module.h>

MODULE_DESCRIPTION("An awesome test module.");
MODULE_AUTHOR("Tudor Butufei");
MODULE_LICENSE("GPL");

/* custom log message header; used by pr_* */
#ifdef pr_fmt
#undef pr_fmt
#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt
#endif

/* init - module initialization callback
 *  @return :  0 if everything went well ==> module is loaded
 *            -1 if an error ocurred     ==> module is not loaded
 */
static int init(void)
{
    pr_info("Hello world from test module!\n");
 
    return 0;
}

/* fini - module removal callback
 */
static void fini(void)
{
    pr_info("Goodbye cruel, cruel world!\n");
}

/* register on_init and on_exit event handlers */
module_init(init);
module_exit(fini);
