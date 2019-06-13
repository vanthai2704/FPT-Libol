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
                return RedirectToAction("Index", "Home");
            }
            else
            {
                ViewData["Notification"] = "Tên đăng nhập/mật khẩu không đúng!";
                return View();
            }

        }

        public ActionResult Logout()
        {
            Session["UserID"] = null;
            return View();
        }
    }
}