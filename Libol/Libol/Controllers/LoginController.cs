using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using XCrypt;
using Libol.Models;

namespace Libol.Controllers
{
    public class LoginController : Controller
    {
        private LibolEntities db = new LibolEntities();
        // GET: Login
        public ActionResult Index()
        {
            if (Session["UserID"] != null)
            {
                return RedirectToAction("Index", "Home");
            }
            return View();
        }

        [HttpPost]
        public ActionResult Index(string username, string password)
        {
            string passEncrypt = new XCryptEngine(XCryptEngine.AlgorithmType.MD5).Encrypt(password, "pl");
            List<SP_SYS_USER_LOGIN_Result> checkUser = db.SP_SYS_USER_LOGIN(username, passEncrypt).ToList();
            if (checkUser != null && checkUser.Count > 0)
            {
                Session["UserID"] = checkUser[0].ID;
                Session["FullName"] = checkUser[0].Name;
                return RedirectToAction("Index", "Home");
            }
            else
            {
                ViewData["Notification"] = "Tên đăng nhập/mật khẩu không đúng!";
                return View();
            }

        }

        [HttpPost]
        public JsonResult SignInWithGoogle(string email)
        {
            SYS_USER_GOOGLE_ACCOUNT acc = db.SYS_USER_GOOGLE_ACCOUNT.Find(email);
            if (acc != null)
            {
                Session["UserID"] = acc.ID;
                return Json("", JsonRequestBehavior.AllowGet);
            }
            else
            {

                return Json("EmailNotExist", JsonRequestBehavior.AllowGet);
            }

        }

        [HttpPost]
        public JsonResult Logout()
        {
            Session.Abandon();
            return Json("", JsonRequestBehavior.AllowGet);
        }
    }
}