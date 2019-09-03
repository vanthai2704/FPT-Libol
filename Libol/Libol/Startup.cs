using System;
using System.Threading.Tasks;
using Hangfire;
using Libol.Controllers;
using Libol.SupportClass;
using Microsoft.Owin;
using Owin;

[assembly: OwinStartup(typeof(Libol.Startup))]

namespace Libol
{
    public class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            //GlobalConfiguration.Configuration.UseSqlServerStorage(@"Data Source=flibserver.database.windows.net;Initial Catalog=flib;User ID=flibadmin;Password=Chipchip11;");
            //app.UseHangfireDashboard();
            //OverdueEmailNoticeController obj = new OverdueEmailNoticeController();
            //RecurringJob.AddOrUpdate(() => obj.SendEmail("hongnhat97tt@gmail.com"), Cron.Daily);
            //app.UseHangfireServer();
        }
    }
}
