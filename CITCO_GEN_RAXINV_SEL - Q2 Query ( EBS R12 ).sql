-- Removed DISTINCT AND replaced _all with org specific views by karthik malli for PERF issue on 12-Apr-2015 on all select statements 
SELECT A.cust_trx_line_id_rev
      ,A.revenue_category_code
      ,B.meaning meaning-- ,A.MEANING -- SG Modified on 5-Feb-2015
      ,A.cust_trx_id_rev
      ,A.long_task_name
      ,A.type
      ,A.bill_through_date
      ,A.service_type_code
      ,A.expenditure_type
      ,A.bill_amount
      ,A.descr
      ,B.predefined_flag
      ,A.expenditure_item_id
      ,A.event_type
      ,A.event_description
FROM (
       SELECT ctrln.customer_trx_line_id cust_trx_line_id_rev
             ,paet.revenue_category_code
                -- ,paet.description
             ,pal.meaning
             ,ctrx.customer_trx_id cust_trx_id_rev
             ,'EVENT' type
             ,pt.long_task_name
             ,pad.bill_through_date
             ,pt.service_type_code
             ,NULL expenditure_type
             ,NULL bill_amount
             ,'ALL' descr  -- Added by Shruti 11/02/2015
             ,NULL expenditure_item_id
             --    ,ctrx.interface_header_attribute1
             ,pae.event_type event_type -- Added by Sithy on 08-Dec-2015 
             ,pae.description event_description -- Added by Sithy on 08-Dec-2015 
       FROM   pa_events pae
             ,pa_draft_invoice_items padi -- pa_draft_invoice_lines_v padi -- Modified by Sithy on 12-Apr-2016 for performance issue
             ,pa_event_types paet
             ,pa_lookups pal
             ,ra_customer_trx ctrx
             ,ra_customer_trx_lines ctrln
             ,pa_projects_all pa
             ,pa_tasks pt
             ,pa_draft_invoices_all pad
       WHERE  pae.event_type                  = paet.event_type
       AND    padi.project_id                 = pae.project_id
       AND    padi.project_id                 = pad.project_id (+) -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = pad.draft_invoice_num(+) -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = ctrln.interface_line_attribute2
       AND    pae.event_num                   = padi.event_num
        --AND   pae.event_id = padi.event_id  -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    pal.lookup_type                 = 'REVENUE CATEGORY'
       AND    pal.lookup_code                 = paet.revenue_category_code
       AND    ctrx.interface_header_context   = 'PROJECTS INVOICES'
       AND    padi.project_id                 = pa.project_id
       AND    pa.project_id                   = pt.project_id
        --AND   PT.TASK_ID        = PAE.TASK_ID
       AND    padi.event_task_id              = pt.task_id
        --AND   pa.segment1       = :PROJECT_NUM
       AND    pa.segment1                     = ctrx.interface_header_attribute1
       AND    ctrx.customer_trx_id            = ctrln.customer_trx_id
        --AND   CTRX.INTERFACE_HEADER_ATTRIBUTE4  = :LEGAL_ENTITY
       AND    ctrx.customer_trx_id            =:customer_trx_id
       AND    padi.project_id                 = pa.project_id
       --AND   PADI.EVENT_ID IS NOT NULL  -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    padi.line_num                   = TRIM(ctrln.interface_line_attribute6)
       AND    pt.service_type_code <> 'RENT_OFFICES'  -- added by Shruti 26/11/2014
       AND    pae.project_id                  = pa.project_id -- added by Karthik Malli for perf issue on 12-Apr-2016
       AND    pae.task_id                     = pt.task_id -- added by Karthik Malli for perf issue on 12-Apr-2016
       AND    pad.system_reference(+)            = ctrx.customer_trx_id -- added by Karthik Malli for perf issue on 12-Apr-2016 -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    pa.project_id                   = pad.project_id  (+) -- added bY Karthik Malli for perf issue on 12-Apr-2016 -- (+) added by ramesh for ERPCM-1057 tie back issue
       UNION
       SELECT ctrln.customer_trx_line_id cust_trx_line_id_rev
             ,NVL(
                  DECODE(ext.revenue_category_code
                        ,'LABOR', 'FEE_REVENUE'
                        ,ext.revenue_category_code)  -- Changed to FEE_REVENUE by Shruti 28/09/2015 -- Added by Shruti 11/02/2015
                 ,(SELECT lookup_code
                   FROM   pa_lookups
                   WHERE  lookup_type = 'CITCO_CUSTOMER_INVOICE_ORDER'
                   AND    meaning = (SELECT lkp.description exp_category
                                     FROM   pa_lookups lkp
                                     WHERE  lkp.lookup_type = 'CITCO CREDIT INVOICE MAPPING'
                                     AND    lkp.lookup_code = pt.task_number)
                   )
                 ) revenue_category_code -- Added NVL by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
                 -- ,paet.description
                 -- Added by Shruti 11/02/2015
             ,NVL(
                  DECODE(pal.meaning
                        ,'Labor',(SELECT DISTINCT meaning
                                  FROM   pa_lookups
                                  WHERE  lookup_type = 'CITCO_CUSTOMER_INVOICE_ORDER'
                                  AND    pal.lookup_code = 'FEE_REVENUE') -- Changed to FEE_REVENUE by Shruti 28/09/2015
                        ,pal.meaning)
                 ,(SELECT lkp.description exp_category
                   FROM   pa_lookups lkp
                   WHERE  lkp.lookup_type = 'CITCO CREDIT INVOICE MAPPING'
                   AND    lkp.lookup_code = pt.task_number)
                 ) meaning -- Added NVL by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
             ,ctrx.customer_trx_id cust_trx_id_rev
             ,'EXP' type
               --,pt.long_task_name ,-- Replaced with CASE by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
             ,CASE
                WHEN DECODE(ext.revenue_category_code
                           ,'LABOR','FEE_REVENUE'
                           ,ext.revenue_category_code) IS NOT NULL 
                THEN pt.long_task_name
                ELSE (SELECT lkp.meaning ||lkp.attribute1 ||lkp.attribute2 long_task_name
                      FROM   pa_lookups lkp
                      WHERE  lkp.lookup_type = 'CITCO CREDIT INVOICE MAPPING'
                      AND    lkp.lookup_code = pt.task_number)
              END long_task_name -- Added CASE by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
             ,pad.bill_through_date
             ,pt.service_type_code
             ,exi.expenditure_type
           -- Modified by Sithy on 07-Dec-2015 for Issue 319
           --,padv.INVPROC_BILL_AMOUNT   -- PADV.BILL_AMOUNT Changed by Shruti 08/10/2015
             ,DECODE(ctrx.invoice_currency_code
                   --padv.invproc_currency_code,padv.invproc_bill_amount,padv.bill_amount)  
                    ,padv.invproc_currency_code,padv.bill_amount
                    ,padv.bill_trans_bill_amount) bill_amount
             ,DECODE(ext.revenue_category_code
                    ,'LABOR','TSK'
                    ,'ALL') descr
             ,exi.expenditure_item_id
             --    ,ctrx.interface_header_attribute1
             ,NULL event_type -- Added by Sithy on 08-Dec-2015 
             ,NULL event_description -- Added by Sithy on 08-Dec-2015 
       FROM   pa_expenditure_items_all exi
             ,pa_expenditure_types ext
             ,pa_lookups pal
             ,ra_customer_trx ctrx
             ,ra_customer_trx_lines ctrln
             ,pa_projects_all pa
             ,pa_tasks pt
             ,pa_draft_invoice_items padi --pa_draft_invoice_lines_v padi -- Modified by Sithy on 12-Apr-2016 for performance issue
             ,pa_draft_invoices_all pad
             ,pa_cust_rev_dist_lines_all padv -- PA_DRAFT_INV_LINE_DETAILS_V padv -- Modified by Sithy on 12-Apr-2016 for performance issue
       WHERE  exi.expenditure_type            = ext.expenditure_type (+) -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND   ((pal.lookup_type = 'REVENUE CATEGORY') OR (pal.lookup_type IS NULL)) -- Added by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       --AND   pal.lookup_type    = 'REVENUE CATEGORY' -- Commented by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    ctrx.interface_header_context   = 'PROJECTS INVOICES'
       AND    pal.lookup_code (+) = ext.revenue_category_code -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       --AND   pa.project_id     = exi.project_id -- Commented by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    padi.project_id                 = padv.project_id (+) -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    pa.project_id                   = pt.project_id
       --AND   PT.TASK_ID        = EXI.TASK_ID
       AND    padi.task_id                    = pt.task_id
       --AND    EXI.PROJECT_ID     = PT.PROJECT_ID
       --AND    pa.segment1       = :PROJECT_NUM
       AND    pa.segment1                     = ctrx.interface_header_attribute1
       AND    padi.project_id                 = pad.project_id(+) -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = pad.draft_invoice_num(+)-- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = ctrln.interface_line_attribute2
       AND    ctrx.customer_trx_id            = ctrln.customer_trx_id
       --AND   CTRX.INTERFACE_HEADER_ATTRIBUTE4  = :LEGAL_ENTITY
       AND    ctrx.customer_trx_id            =:customer_trx_id
       AND    padi.project_id                 = pa.project_id
       --AND   PADI.EVENT_ID IS NULL   -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    padi.line_num                   = TRIM(ctrln.interface_line_attribute6)
       AND    pt.service_type_code <> 'RENT_OFFICES'  -- added by Shruti 26/11/2014
       AND    padi.draft_invoice_num          = padv.draft_invoice_num (+)           -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    padv.expenditure_item_id        = exi.expenditure_item_id (+)          -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    padi.line_num                   = padv.draft_invoice_item_line_num (+) -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       AND    pad.system_reference  (+)            = ctrx.customer_trx_id               -- added by karthik malli for perf issue on 12-Apr-2016 -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    pa.project_id                   = pad.project_id        (+)                     -- adeed by karthik malli for perf issue on 12-Apr-2016 -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.event_task_id IS NULL                                             -- Added by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
       UNION
       SELECT ctrln.customer_trx_line_id cust_trx_line_id_rev
             ,'Rent' revenue_category_code
                -- ,paet.description
             ,'Rent' meaning
             ,ctrx.customer_trx_id cust_trx_id_rev
             ,'EVENT' type
             ,pt.long_task_name
             ,pad.bill_through_date
             ,pt.service_type_code
             ,NULL expenditure_type
             ,NULL bill_amount
             ,'ALL' descr  -- Added by Shruti 11/02/2015
             ,NULL expenditure_item_id
             --    ,ctrx.interface_header_attribute1
             ,pae.event_type event_type -- Added by Sithy on 08-Dec-2015 
             ,pae.description event_description -- Added by Sithy on 08-Dec-2015 
       FROM   pa_events pae
             ,pa_draft_invoice_items padi -- pa_draft_invoice_lines_v padi -- Modified by Sithy on 12-Apr-2016 for performance issue
             ,pa_event_types paet
             ,pa_lookups pal
             ,ra_customer_trx ctrx
             ,ra_customer_trx_lines ctrln
             ,pa_projects_all pa
             ,pa_tasks pt
             ,pa_draft_invoices_all pad
       WHERE  pae.event_type                  = paet.event_type
       AND    padi.project_id                 = pae.project_id
       AND    padi.project_id                 = pad.project_id(+)   -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = pad.draft_invoice_num (+)   -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = ctrln.interface_line_attribute2
       AND    pae.event_num                   = padi.event_num
        --AND   pae.event_id        = padi.event_id -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    pal.lookup_type                 = 'REVENUE CATEGORY'
       AND    pal.lookup_code                 = paet.revenue_category_code
       AND    ctrx.interface_header_context   = 'PROJECTS INVOICES'
       AND    padi.project_id                 = pa.project_id
       AND    pa.project_id                   = pt.project_id
        --AND   PT.TASK_ID        = PAE.TASK_ID
       AND    padi.event_task_id              = pt.task_id
        --AND   pa.segment1       = :PROJECT_NUM
       AND    pa.segment1                     = ctrx.interface_header_attribute1
       AND    ctrx.customer_trx_id            = ctrln.customer_trx_id
        --AND   CTRX.INTERFACE_HEADER_ATTRIBUTE4  = :LEGAL_ENTITY
       AND    ctrx.customer_trx_id            =:customer_trx_id
       AND    padi.project_id                 = pa.project_id
        --AND   PADI.EVENT_ID IS not  NULL  -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    padi.line_num                   = TRIM(ctrln.interface_line_attribute6)
       AND    pt.service_type_code            = 'RENT_OFFICES'  -- added by Shruti 26/11/2014
       AND    pae.project_id                  = pa.project_id -- added by Karthik Malli for perf issue on 12-Apr-2016
       AND    pae.task_id                     = pt.task_id -- added by Karthik Malli for perf issue on 12-Apr-2016
       AND    pad.system_reference(+)            = ctrx.customer_trx_id -- added by Karthik Malli for Perf issue on 12-Apr-2016  -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    pa.project_id                   = pad.project_id  (+)  -- added by Karthik Malli for PERF issue  on 12-Apr-2016  -- (+) added by ramesh for ERPCM-1057 tie back issue
       UNION
       SELECT ctrln.customer_trx_line_id cust_trx_line_id_rev
             ,'Rent' revenue_category_code
                -- ,paet.description
             ,'Rent' meaning
             ,ctrx.customer_trx_id cust_trx_id_rev
             ,'EXP' type
             ,NVL(pt.long_task_name
                ,(SELECT lkp.meaning ||lkp.attribute1 ||lkp.attribute2 long_task_name
                  FROM   pa_lookups lkp
                  WHERE  lkp.lookup_type  = 'CITCO CREDIT INVOICE MAPPING'
                  AND    lkp.lookup_code  = pt.task_number)
                 ) long_task_name -- Added NVL by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
             ,pad.bill_through_date
             ,pt.service_type_code
             ,exi.expenditure_type
           -- Modified by Sithy on 07-Dec-2015 for Issue 319
           --,padv.INVPROC_BILL_AMOUNT   -- PADV.BILL_AMOUNT Changed by Shruti 08/10/2015
             ,DECODE(ctrx.invoice_currency_code,
                   --padv.invproc_currency_code,padv.invproc_bill_amount,padv.bill_amount) 
                      padv.invproc_currency_code, padv.bill_amount
                     ,padv.bill_trans_bill_amount) bill_amount
             ,'ALL' descr  -- Added by Shruti 11/02/2015
             ,exi.expenditure_item_id
             --    ,ctrx.interface_header_attribute1
             ,NULL event_type -- Added by Sithy on 08-Dec-2015 
             ,NULL event_description -- Added by Sithy on 08-Dec-2015 
       FROM   pa_expenditure_items_all exi
             ,pa_expenditure_types ext
             ,pa_lookups pal
             ,ra_customer_trx ctrx
             ,ra_customer_trx_lines ctrln
             ,pa_projects_all pa
             ,pa_tasks pt
             ,pa_draft_invoice_items padi -- pa_draft_invoice_lines_v padi,-- Modified by Sithy on 12-Apr-2016 for performance issue
             ,pa_draft_invoices_all pad
             ,pa_cust_rev_dist_lines_all padv --PA_DRAFT_INV_LINE_DETAILS_V padv  -- Modified by Sithy on 12-Apr-2016 for performance issue
       WHERE  exi.expenditure_type           = ext.expenditure_type (+) -- Added by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND   ((pal.lookup_type = 'REVENUE CATEGORY') OR (pal.lookup_type IS NULL)) -- Added by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       --AND   pal.lookup_type    = 'REVENUE CATEGORY' -- Commented by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    ctrx.interface_header_context   = 'PROJECTS INVOICES'
       AND    pal.lookup_code (+) = ext.revenue_category_code -- Commented by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       --AND   pa.project_id = exi.project_id  -- Remove by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    padi.project_id                 = padv.project_id (+) -- Added by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    pa.project_id                   = pt.project_id
       --AND   PT.TASK_ID = EXI.TASK_ID
       AND    padi.task_id                    = pt.task_id
       --AND    EXI.PROJECT_ID = PT.PROJECT_ID
       --AND    pa.segment1 = :PROJECT_NUM
       AND    pa.segment1                     = ctrx.interface_header_attribute1
       AND    padi.project_id                 = pad.project_id(+) -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = pad.draft_invoice_num(+) -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.draft_invoice_num          = ctrln.interface_line_attribute2
       AND    ctrx.customer_trx_id            = ctrln.customer_trx_id
       --AND   CTRX.INTERFACE_HEADER_ATTRIBUTE4  = :LEGAL_ENTITY
       AND    ctrx.customer_trx_id            =:customer_trx_id
       AND    padi.project_id                 = pa.project_id
       --AND   PADI.EVENT_ID IS NULL  -- Commented by Sithy on 12-Apr-2016 for performance issue
       AND    padi.line_num                   = TRIM(ctrln.interface_line_attribute6)
       AND    pt.service_type_code            = 'RENT_OFFICES'  -- added by Shruti 26/11/2014
       AND    padi.draft_invoice_num          = padv.draft_invoice_num (+)            -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    padv.expenditure_item_id        = exi.expenditure_item_id (+)           -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    padi.line_num                   = padv.draft_invoice_item_line_num (+)  -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
       AND    pad.system_reference  (+)          = ctrx.customer_trx_id            -- added by Karthik Malli for perf issue on 12-Apr-2016 -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    pa.project_id                   = pad.project_id      (+)                     -- added by Karthik Malli for perf issue on 12-Apr-2016    -- (+) added by ramesh for ERPCM-1057 tie back issue
       AND    padi.event_task_id IS NULL                                              -- Added by J.Carpio for (JIRA ERPCM-460) on 25-Jul-2017
      ) A
      ,pa_lookups B
WHERE  B.lookup_code (+) = DECODE(A.revenue_category_code, 'Rent', 'RENT'
                                                         , A.revenue_category_code) -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
AND    B.lookup_type (+) = 'CITCO_CUSTOMER_INVOICE_ORDER'                           -- Added outer join by J.Carpio for (JIRA ERPCM-460) on 18-May-2017
ORDER BY B.predefined_flag ASC;