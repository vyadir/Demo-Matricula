from __future__ import annotations

import csv
from io import StringIO

from fastapi import APIRouter, Depends, Request
from fastapi.responses import Response

from app.deps import role_required
from app.services.reports import enrollment_report, financial_report
from app.templating import base_context, templates

router = APIRouter(prefix="/reports", tags=["reports"])


@router.get("")
def reports_page(request: Request, user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO", "TESORERIA", "AUDITOR"))):
    context = base_context(request)
    context.update({"enrollment": enrollment_report(), "financial": financial_report()})
    return templates.TemplateResponse("reports.html", context)


@router.get("/export/{report_name}.csv")
def export_report(report_name: str, user: dict = Depends(role_required("ADMIN_TI", "REGISTRO_ACADEMICO", "TESORERIA", "AUDITOR"))):
    if report_name == "matriculas":
        rows = enrollment_report()
        filename = "reporte_matriculas.csv"
    elif report_name == "finanzas":
        rows = financial_report()
        filename = "reporte_financiero.csv"
    else:
        rows = []
        filename = "reporte.csv"

    output = StringIO()
    writer = csv.writer(output)
    if rows:
        writer.writerow(rows[0].keys())
        for row in rows:
            writer.writerow(row.values())

    return Response(
        content=output.getvalue(),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )
