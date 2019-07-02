using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;
using Libol.SupportClass;

namespace Libol.Controllers
{
    public class ManagementController : BaseController
    {
        private LibolEntities db = new LibolEntities();
        // GET: Management
        public ActionResult Account()
        {
            return View();
        }

        [HttpPost]
        public JsonResult Account(DataTableAjaxPostModel model)
        {
            var users = db.SYS_USER;
            var search = users.Where(a => true);
            if(model.search.value != null)
            {
                string searchValue = model.search.value;
                search = search.Where(a => a.Username.Contains(searchValue));
            }
            if (model.columns[1].search.value != null)
            {
                string searchValue = model.columns[1].search.value;
                search = search.Where(a =>  a.Username.Contains(searchValue));
            }
            if (model.columns[2].search.value != null)
            {
                string searchValue = model.columns[2].search.value;
                search = search.Where(a => a.Name.Contains(searchValue));
            }

            var sorting = search.OrderBy(a => a.ID);
            if (model.order[0].column == 1)
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
            else if (model.order[0].column == 2)
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
        

    }

    public class CustomUser
    {
        public int ID { get; set; }
        public string Name { get; set; }
        public string Username { get; set; }
    }
}