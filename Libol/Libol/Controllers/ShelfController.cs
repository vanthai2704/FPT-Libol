using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

namespace Libol.Controllers
{
    public class ShelfController : BaseController
    {
        LibolEntities libol = new LibolEntities();
        // GET: Shelf
        public ActionResult Index()
        {
            //get list marc form
            ViewData["ListNBS"] = libol.ACQ_ACQUIRE_SOURCE.OrderBy(d => d.ID).ToList();
            //Cấp thư mục
            ViewData["listKTL"] = libol.CIR_LOAN_TYPE.ToList();
            ViewData["ListCurrency"] = libol.ACQ_CURRENCY.OrderBy(d => d.CurrencyCode).ToList();
            return View();

        }

       
    }
}