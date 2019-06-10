using System;
using System.Collections.Generic;
using System.Data;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Mvc;
using Libol.Models;

namespace Libol.Controllers
{
    public class CIR_PATRONController : Controller
    {
        private LibolEntities db = new LibolEntities();

        // GET: CIR_PATRON
        public ActionResult Index()
        {
            var cIR_PATRON = db.CIR_PATRON.Include(c => c.CIR_DIC_EDUCATION).Include(c => c.CIR_DIC_ETHNIC).Include(c => c.CIR_DIC_OCCUPATION).Include(c => c.CIR_PATRON_GROUP).Include(c => c.CIR_PATRON_UNIVERSITY);
            return View(cIR_PATRON.ToList());
        }


        public ActionResult PatronProfile()
        {
            return View();
        }


        // GET: CIR_PATRON/Details/5
        public ActionResult Details(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            CIR_PATRON cIR_PATRON = db.CIR_PATRON.Find(id);
            if (cIR_PATRON == null)
            {
                return HttpNotFound();
            }
            return View(cIR_PATRON);
        }

        // GET: CIR_PATRON/Create
        public ActionResult Create()
        {
            ViewBag.EducationID = new SelectList(db.CIR_DIC_EDUCATION, "ID", "EducationLevel");
            ViewBag.EthnicID = new SelectList(db.CIR_DIC_ETHNIC, "ID", "Ethnic");
            ViewBag.OccupationID = new SelectList(db.CIR_DIC_OCCUPATION, "ID", "Occupation");
            ViewBag.PatronGroupID = new SelectList(db.CIR_PATRON_GROUP, "ID", "Name");
            ViewBag.ID = new SelectList(db.CIR_PATRON_UNIVERSITY, "PatronID", "Grade");
            return View();
        }

        // POST: CIR_PATRON/Create
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see https://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Create([Bind(Include = "ID,Code,ValidDate,ExpiredDate,LastIssuedDate,LastName,FirstName,MiddleName,Sex,DOB,EthnicID,EducationID,OccupationID,WorkPlace,Telephone,Mobile,Email,Portrait,PatronGroupID,Password,Status,Note,Debt,LastModifiedDate,InterestedSubjectBBK,InterestedSubjectDDC,IDCard")] CIR_PATRON cIR_PATRON)
        {
            if (ModelState.IsValid)
            {
                db.CIR_PATRON.Add(cIR_PATRON);
                db.SaveChanges();
                return RedirectToAction("Index");
            }

            ViewBag.EducationID = new SelectList(db.CIR_DIC_EDUCATION, "ID", "EducationLevel", cIR_PATRON.EducationID);
            ViewBag.EthnicID = new SelectList(db.CIR_DIC_ETHNIC, "ID", "Ethnic", cIR_PATRON.EthnicID);
            ViewBag.OccupationID = new SelectList(db.CIR_DIC_OCCUPATION, "ID", "Occupation", cIR_PATRON.OccupationID);
            ViewBag.PatronGroupID = new SelectList(db.CIR_PATRON_GROUP, "ID", "Name", cIR_PATRON.PatronGroupID);
            ViewBag.ID = new SelectList(db.CIR_PATRON_UNIVERSITY, "PatronID", "Grade", cIR_PATRON.ID);
            return View(cIR_PATRON);
        }

        // GET: CIR_PATRON/Edit/5
        public ActionResult Edit(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            CIR_PATRON cIR_PATRON = db.CIR_PATRON.Find(id);
            if (cIR_PATRON == null)
            {
                return HttpNotFound();
            }
            ViewBag.EducationID = new SelectList(db.CIR_DIC_EDUCATION, "ID", "EducationLevel", cIR_PATRON.EducationID);
            ViewBag.EthnicID = new SelectList(db.CIR_DIC_ETHNIC, "ID", "Ethnic", cIR_PATRON.EthnicID);
            ViewBag.OccupationID = new SelectList(db.CIR_DIC_OCCUPATION, "ID", "Occupation", cIR_PATRON.OccupationID);
            ViewBag.PatronGroupID = new SelectList(db.CIR_PATRON_GROUP, "ID", "Name", cIR_PATRON.PatronGroupID);
            ViewBag.ID = new SelectList(db.CIR_PATRON_UNIVERSITY, "PatronID", "Grade", cIR_PATRON.ID);
            return View(cIR_PATRON);
        }

        // POST: CIR_PATRON/Edit/5
        // To protect from overposting attacks, please enable the specific properties you want to bind to, for 
        // more details see https://go.microsoft.com/fwlink/?LinkId=317598.
        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Edit([Bind(Include = "ID,Code,ValidDate,ExpiredDate,LastIssuedDate,LastName,FirstName,MiddleName,Sex,DOB,EthnicID,EducationID,OccupationID,WorkPlace,Telephone,Mobile,Email,Portrait,PatronGroupID,Password,Status,Note,Debt,LastModifiedDate,InterestedSubjectBBK,InterestedSubjectDDC,IDCard")] CIR_PATRON cIR_PATRON)
        {
            if (ModelState.IsValid)
            {
                db.Entry(cIR_PATRON).State = EntityState.Modified;
                db.SaveChanges();
                return RedirectToAction("Index");
            }
            ViewBag.EducationID = new SelectList(db.CIR_DIC_EDUCATION, "ID", "EducationLevel", cIR_PATRON.EducationID);
            ViewBag.EthnicID = new SelectList(db.CIR_DIC_ETHNIC, "ID", "Ethnic", cIR_PATRON.EthnicID);
            ViewBag.OccupationID = new SelectList(db.CIR_DIC_OCCUPATION, "ID", "Occupation", cIR_PATRON.OccupationID);
            ViewBag.PatronGroupID = new SelectList(db.CIR_PATRON_GROUP, "ID", "Name", cIR_PATRON.PatronGroupID);
            ViewBag.ID = new SelectList(db.CIR_PATRON_UNIVERSITY, "PatronID", "Grade", cIR_PATRON.ID);
            return View(cIR_PATRON);
        }

        // GET: CIR_PATRON/Delete/5
        public ActionResult Delete(int? id)
        {
            if (id == null)
            {
                return new HttpStatusCodeResult(HttpStatusCode.BadRequest);
            }
            CIR_PATRON cIR_PATRON = db.CIR_PATRON.Find(id);
            if (cIR_PATRON == null)
            {
                return HttpNotFound();
            }
            return View(cIR_PATRON);
        }

        // POST: CIR_PATRON/Delete/5
        [HttpPost, ActionName("Delete")]
        [ValidateAntiForgeryToken]
        public ActionResult DeleteConfirmed(int id)
        {
            CIR_PATRON cIR_PATRON = db.CIR_PATRON.Find(id);
            db.CIR_PATRON.Remove(cIR_PATRON);
            db.SaveChanges();
            return RedirectToAction("Index");
        }


        protected override void Dispose(bool disposing)
        {
            if (disposing)
            {
                db.Dispose();
            }
            base.Dispose(disposing);
        }






    }
}
