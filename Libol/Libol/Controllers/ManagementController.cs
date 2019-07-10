﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.SupportClass;
using XCrypt;

namespace Libol.Controllers
{
    public class ManagementController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        // GET: Management
        public ActionResult Account(string username)
        {
            if (!String.IsNullOrEmpty(username))
            {
                if (db.SYS_USER.Where(a => a.Username == username).Count() > 0)
                {
                    SYS_USER user = db.SYS_USER.Where(a => a.Username == username).First();
                    ViewBag.GoogleAccount = db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID == user.ID).FirstOrDefault();
                    return View(user);
                }
                else
                {
                    return View(new SYS_USER());
                }
            }
            else
            {
                return View(new SYS_USER());
            }

        }

        [HttpPost]
        public JsonResult Account(DataTableAjaxPostModel model)
        {
            var users = db.SYS_USER;
            var search = users.Where(a => true);
            if (model.search.value != null)
            {
                string searchValue = model.search.value;
                search = search.Where(a => a.Username.Contains(searchValue) || a.Name.Contains(searchValue));
            }
            if (model.columns[1].search.value != null)
            {
                string searchValue = model.columns[1].search.value;
                search = search.Where(a => a.Username.Contains(searchValue));
            }
            if (model.columns[2].search.value != null)
            {
                string searchValue = model.columns[2].search.value;
                search = search.Where(a => a.Name.Contains(searchValue));
            }

            var sorting = search.OrderBy(a => a.ID);
            if (model.order[0].column == 2)
            {
                if (model.order[0].dir.Equals("asc"))
                {
                    sorting = search.OrderBy(a => a.Username);
                }
                else
                {
                    sorting = search.OrderByDescending(a => a.Username);
                }

            }
            else if (model.order[0].column == 3)
            {
                if (model.order[0].dir.Equals("asc"))
                {
                    sorting = search.OrderBy(a => a.Name);
                }
                else
                {
                    sorting = search.OrderByDescending(a => a.Name);
                }

            }
            var paging = sorting.Skip(model.start).Take(model.length).ToList();
            var result = new List<CustomUser>(paging.Count);
            foreach (var s in paging)
            {
                result.Add(new CustomUser
                {
                    ID = s.ID,
                    Name = s.Name,
                    Username = s.Username
                });
            };
            return Json(new
            {
                draw = model.draw,
                recordsTotal = users.Count(),
                recordsFiltered = search.Count(),
                data = result
            });
        }

        [HttpPost]
        public JsonResult UpdateUser(int ID, string Name, string Username, string Email, string Password, string RepeatPassword)
        {
            if (db.SYS_USER.Where(a => a.ID != ID).Where(a => a.Username == Username).Count() > 0)
            {
                return Json(new Result()
                {
                    CodeError = 2,
                    Data = "Người dùng với tên đăng nhập <strong style='color:black; '>" + Username + "</strong> đã tồn tại!"
                }, JsonRequestBehavior.AllowGet);
            }
            if (db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID != ID).Where(a => a.Email == Email).Count() > 0)
            {
                return Json(new Result()
                {
                    CodeError = 2,
                    Data = "Người dùng với email <strong style='color:black; '>" + Email + "</strong> đã tồn tại!"
                }, JsonRequestBehavior.AllowGet);
            }
            string InvalidFields = "";
            if (String.IsNullOrEmpty(Name))
            {
                InvalidFields += "txtName-";
            }
            if (String.IsNullOrEmpty(Email))
            {
                InvalidFields += "txtEmail-";
            }
            if (String.IsNullOrEmpty(Username))
            {
                InvalidFields += "txtUsername-";
            }
            if (!String.IsNullOrEmpty(Password) && Password != RepeatPassword)
            {
                InvalidFields += "txtRepeatPassword-";
            }
            if (InvalidFields != "")
            {
                return Json(new Result()
                {
                    CodeError = 1,
                    Data = InvalidFields
                }, JsonRequestBehavior.AllowGet);
            }
            else
            {
                var user = db.SYS_USER.Where(a => a.ID == ID).First();
                user.Name = Name;
                user.Username = Username;
                if (!String.IsNullOrEmpty(Password))
                {
                    string passEncrypt = new XCryptEngine(XCryptEngine.AlgorithmType.MD5).Encrypt(Password, "pl");
                    user.Password = passEncrypt;
                }

                if (db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID == ID).Count() > 0)
                {
                    var userGoogleAccount = db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID == ID).First();
                    userGoogleAccount.Email = Email;
                }
                else
                {

                    var userGoogleAccount = db.SYS_USER_GOOGLE_ACCOUNT.Create();
                    userGoogleAccount.ID = ID;
                    userGoogleAccount.Email = Email;
                    db.SYS_USER_GOOGLE_ACCOUNT.Add(userGoogleAccount);
                }
                db.SaveChanges();
                return Json(new Result()
                {
                    CodeError = 0,
                    Data = "Tài khoản <strong style='color:black;'>" + Username + " </strong> đã được cập nhật thành công cho <strong style='color:black;'>" + Name + "</strong>"
                }, JsonRequestBehavior.AllowGet);
            }
        }

        [HttpPost]
        public JsonResult DeleteUser(string strUIDs)
        {
            try
            {
                int result = db.SP_ADMIN_DELETE_USER(strUIDs);
                if (result > 0)
                {
                    var IDs = strUIDs.Split(',');
                    foreach (var ID in IDs)
                    {
                        if (db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID.ToString() == ID).Count() > 0)
                        {
                            var googleAcc = db.SYS_USER_GOOGLE_ACCOUNT.Where(a => a.ID.ToString() == ID).First();
                            db.SYS_USER_GOOGLE_ACCOUNT.Remove(googleAcc);
                        }
                    }
                    db.SaveChanges();
                    return Json("", JsonRequestBehavior.AllowGet);
                }
                else
                {
                    return Json("error", JsonRequestBehavior.AllowGet);
                }
            }
            catch (Exception)
            {
                return Json("error", JsonRequestBehavior.AllowGet);
            }

        }

        [HttpPost]
        public JsonResult GetRightInModule(int module, int UserID)
        {
            Rights rights = new Rights();
            
            

            return Json(rights, JsonRequestBehavior.AllowGet);
        }
    }
    public class CustomUser
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public string Username { get; set; }
    }

    public class Rights
    {
        public List<UserRight> Accept { get; set; }
        public List<UserRight> Deny { get; set; }
    }

    public class UserRight
    {
        public int ID { get; set; }
        public string Right { get; set; }
    }
}