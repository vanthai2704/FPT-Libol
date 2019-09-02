﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web;
using System.Web.Hosting;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class OverdueEmailNoticeController : Controller
    {
        // GET: OverdueNotice
        public ActionResult Index()
        {
            return View();
        }

        public async Task<ActionResult> SendEmail(string toEmail)
        {
            //Email
            var message = EmailTemplate("NoticeEmail");
            await SendEmailAsync(toEmail, "Library's Overdue notice", message);
            //End
            return Json(0, JsonRequestBehavior.AllowGet);
        }

        public string EmailTemplate(string template)
        {
            string body = System.IO.File.ReadAllText(HostingEnvironment.MapPath("~/Content/EmailTemplate/") + template + ".cshtml");
            body = body.Replace("|Name-Placeholder|", "Phan Trường Lâm (Load from db)");
            body = body.Replace("|Time-Placeholder|", "have (has) due date tomorrow (Load from db)");
            body = body.Replace("|Title-Placeholder|", "Summit 2 (Load from db)");
            body = body.Replace("|BarcodeNumber-Placeholder|", "Barcodenumber (Load from db)");
            body = body.Replace("|DueDate-Placeholder|", "03/09/2019 (Load from db)");
            return body;
        }

        public async static Task SendEmailAsync(string email, string subject, string message)
        {
            try
            {
                //step1 set setting public to email account
                
                //step2 send mail
                var _email = "trinhlv26031997@gmail.com";
                var _pass = "Iphone1997";
                var _name = "FPT University Library";
                MailMessage myMessage = new MailMessage();
                myMessage.To.Add(email);
                myMessage.From = new MailAddress(_email, _name);
                myMessage.Subject = subject;
                myMessage.Body = message;
                myMessage.IsBodyHtml = true;

                using (SmtpClient smtp = new SmtpClient())
                {
                    smtp.EnableSsl = true;
                    smtp.Host = "smtp.gmail.com";
                    smtp.Port = 587;
                    smtp.UseDefaultCredentials = false;
                    smtp.Credentials = new NetworkCredential(_email, _pass);
                    smtp.DeliveryMethod = SmtpDeliveryMethod.Network;
                    smtp.SendCompleted += (s, e) =>
                    {
                        smtp.Dispose();
                    };
                    await smtp.SendMailAsync(myMessage);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }
    }
}