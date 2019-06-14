using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace Libol.Controllers
{
    public class CatalogueController : Controller
    {
        // GET: Catalogue
        public ActionResult MainTab()
        {
            return View();
        }

        public ActionResult AddNewCatalogue()
        {
            return View();
        }

        public ActionResult SearchView()
        {
            return View();
        }


        public ActionResult SearchCodeNumber()
        {
            return View();
        }
        

            public ActionResult UpdateCatalogue()
        {
            return View();
        }
    }
}