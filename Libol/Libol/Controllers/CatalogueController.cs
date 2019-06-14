using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

namespace Libol.Controllers
{
    public class CatalogueController : Controller
    {
        private LibolEntities db = new LibolEntities();

        // GET: Catalogue
        public ActionResult MainTab()
        {
            int a = db.SP_CATA_GET_MARC_FORM(0, 0);
            return View(db.SP_CATA_GET_MARC_FORM(0, 1));
        }

        public ActionResult AddNewCatalogue()
        {
            return View( );
        }

        //public ActionResult CreateForm()
        //{
        //    return View();
        //}

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