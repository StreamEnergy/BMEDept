USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_ISTA_MEI_Script]    Script Date: 08/25/2014 12:20:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date				Author						Description
10/24/2013			Darren Williams				Purpose of this SP is for the MEI Report. To run the queries that ISTA gave us.
10/24/2013			Darren Williams				Initial Release [usp_ISTA_MEI_Script] .
												Purpose of this SP is for the MEI Report. To run the queries that ISTA gave us.
08/15/2014			Jide Akintoye				Format Stored Procedure




**********************************************************************************************/





CREATE PROCEDURE [dbo].[sp_ISTA_MEI_Script] ( @enddate DATETIME )
AS
    BEGIN



--declare @enddate datetime 
--set @enddate = '9/30/2013 23:59:59' 

        DECLARE @StartOfMonth DATETIME;
        DECLARE @EndOfMonth DATETIME;

        SELECT  @StartOfMonth = DATEADD(MONTH , DATEDIFF(MONTH , 0 , @enddate) ,
                                        0)
        SELECT  @EndOfMonth = DATEADD(MILLISECOND , -3 ,
                                      DATEADD(MONTH ,
                                              DATEDIFF(MONTH , 0 , @enddate)
                                              + 1 , 0))

  
--==========================================================
--for all cancellations, find original and rebill
--===========================================================
/*  todo: (1) check CTR process flag? (27985 row(s) affected)
		  (2) How many cancel w/o rebill
		  (3) How many rebill covers multiple cancelled cycles
		  (4) How many rebill includes cancelled + new cycle (custid = 103645)

*/
        SELECT DISTINCT
                t.CustID ,
                t.PremID ,
                t.ESIID ,
                c.RequestID AS XRequestID ,
                t.TransactionNumber AS XTrxnNo , /*c.CreateDate as XCreateDt,*/
                c.DateFrom XDateFrom ,
                c.DateTo XDateTo ,
                DATEDIFF(d , c.DateFrom , c.DateTo) XDays ,
                t.ReferenceNumber XRefNo ,
                c2.RequestID AS ORGRequestID , /*c2.CreateDate as ORGCreateDt,*/
                t2.TransactionNumber ORGTrxnNo ,
                c2.DateFrom ORGDateFrom ,
                c2.DateTo ORGDateTo ,
                DATEDIFF(d , c2.DateFrom , c2.DateTo) ORGDays ,
                rr.RequestID AS RBLRequestID ,
                rr.TransactionNumber AS RBLTrxnNo ,
                rr.DateFrom AS RBLDateFrom ,
                rr.DateTo AS RBLDateTo ,
                rr.REBILLDays AS RBLDays
        INTO    #cancelrebill
        FROM    Stream.dbo.Consumption c
        LEFT JOIN Stream.dbo.CustomerTransactionRequest t ON c.RequestID = t.RequestID
        LEFT JOIN Stream.dbo.CustomerTransactionRequest t2 ON t.ReferenceNumber = t2.TransactionNumber
                                                              AND t2.TransactionType = '867'
                                                              AND t2.ServiceAction = '00'
        LEFT JOIN Stream.dbo.Consumption c2 ON t2.RequestID = c2.RequestID
        LEFT JOIN --> find original that's not tied to cancel with overlapping service period = These are the REBILLs
                ( SELECT    cr.RequestID ,
                            tr.TransactionNumber ,
                            cr.CreateDate ,
                            cr.DateFrom ,
                            cr.DateTo ,
                            DATEDIFF(d , cr.DateFrom , cr.DateTo) REBILLDays ,
                            tr.ESIID ,
                            tr.PremID ,
                            tr.CustID ,
                            tx.ReferenceNumber
                  FROM      Stream.dbo.Consumption cr
                  LEFT JOIN Stream.dbo.CustomerTransactionRequest tr ON cr.RequestID = tr.RequestID
                  LEFT JOIN Stream.dbo.CustomerTransactionRequest tx ON tx.ReferenceNumber = tr.TransactionNumber
                                                              AND tx.TransactionType = '867'
                                                              AND tx.ServiceAction = '01' -->
                  WHERE     tr.ServiceAction = '00'
                            AND tx.ReferenceNumber IS NULL --and tr.CustID = '104639'--'150145'
                ) rr ON rr.CustID = t.CustID
                        AND rr.PremID = t.PremID
                        AND ( ( rr.DateFrom >= c.DateFrom
                                AND rr.DateFrom <= c.DateTo
                              )		--> overlapping srv period (DateFrom)
                              OR ( rr.DateTo >= c.DateFrom
                                   AND rr.DateTo <= c.DateTo
                                 )		--> overlapping srv period (DateTo)
                              OR ( rr.DateFrom < c.DateFrom
                                   AND rr.DateTo > c.DateTo
                                 )		--> overlapping srv period (blanket over one or more cycle)
                            )
                        AND rr.DateTo <> c.DateFrom					--> make sure the overlapping is not because dateto = datefrom (eg cycle from 3/15-4/15, 4/15/-5/15) 
                        AND rr.DateFrom <> c.DateTo				--> make sure the overlapping is not because dateto = datefrom (eg cycle from 3/15-4/15, 4/15/-5/15) 					
                        AND rr.CreateDate > c2.CreateDate	--> rebill could happen before cancel, as long as rebill is after original
        WHERE   t.ServiceAction = '01'
                AND t.TransactionType = '867'		--> Cancel CONS
--and ((c.DateFrom <> c2.DateFrom) or (c.DateTo <> c2.DateTo))	--> out of whack: ORG vs. Cancel = 1,509
--and ((c.DateFrom = c2.DateFrom) and (c.DateTo = c2.DateTo))	--> in synch: ORG vs. Cancel = 21,890
--and t.CustID = 106467--132795--152026--103645--94422--23448--82409--42057--150145--'104639'-- '150145'--'122548'--'200036'
--order by t.TransactionNumber

--===========================
--cancel without rebill
--===========================
--select * from #cancelrebill cr where cr.RBLRequestID is null

--======================================================================
-- How many rebill includes cancelled + new cycle (custid = 103645)
-- New cycle in days = RBLDateTo minus max(cancelled DateTo)
-- For now, 1 or more days in new cycle will be flagged/reported and MEI will be payout. Business rules needs to be discussed here
--======================================================================
        SELECT  MAX(cr.XDateTo) XMaxDateTo ,
                MAX(cr.RBLDateFrom) RBLMaxDateFrom ,
                MAX(cr.RBLDateTo) RBLMaxDateTo ,
                DATEDIFF(d , MAX(cr.RBLDateFrom) , MAX(cr.RBLDateTo)) AS RBLDays ,
                DATEDIFF(d , MAX(cr.XDateTo) , MAX(cr.RBLDateTo)) RBLNewCycleDays ,
                cr.RBLRequestID--, cr.CustID, cr.PremID, cr.ESIID 
        INTO    #RBLNewCycle
        FROM    #cancelrebill cr 
--where cr.CustID = 103645
--where cr.RBLRequestID = 2598970
GROUP BY        cr.RBLRequestID--, cr.CustID, cr.PremID, cr.ESIID 
        HAVING  DATEDIFF(d , MAX(cr.XDateTo) , MAX(cr.RBLDateTo)) > 0
--order by DATEDIFF(d,max(cr.XDateTo),MAX(cr.RBLDateTo))

--select * from #RBLNewCycle
--=================================================================
--now, go pull cons records for these, sum by invoiceid
--assumption: InvoiceID and RequestID has a 1 to 1 r'ship except for 447/217 records below
--=================================================================
        SELECT  c.InvoiceID ,
                SUM(cd.ConsDetQty) AS usage ,
                cu.Unit
        INTO    #usage
        FROM    Stream.dbo.Meter m
        LEFT JOIN Stream.dbo.Consumption c ON c.MeterID = m.MeterID
        LEFT JOIN Stream.dbo.ConsumptionDetail cd ON cd.ConsId = c.ConsID
        LEFT JOIN Stream.dbo.ConsumptionUnit cu ON cd.ConsUnitID = cu.ConsUnitID
--	AND cd.ConsUnitID IN  (5, 9, 13) 
--where c.InvoiceID = 448589--503843--2456919
GROUP BY        c.InvoiceID ,
                cu.Unit

--==================================================================
-- REBILL w/ New Cycle logic here....
--==================================================================
        SELECT DISTINCT
                rr.* ,
                cc.InvoiceID ,
                uu.usage ,
                uu.Unit ,
                ROUND(( uu.usage / rr.RBLDays ) * rr.RBLNewCycleDays , 0) AS RBLNewCycleUsage ,
                cr.CustID ,
                cr.ESIID ,
                cr.PremID
        INTO    #RBLNewCycleUsg
        FROM    #RBLNewCycle rr
        LEFT JOIN Stream.dbo.Consumption cc ON rr.RBLRequestID = cc.RequestID
        LEFT JOIN #usage uu ON uu.InvoiceID = cc.InvoiceID
        LEFT JOIN #cancelrebill cr ON rr.RBLRequestID = cr.RBLRequestID
        WHERE   uu.Unit IN ( 'CCF' , 'kWh' , 'THM' )

--=============================================
--Here's the results for MEI Report!! (145102 row(s) affected)/(145133 row(s) affected)
--=============================================
        SELECT  
	--m.PremID,
	--cu.CustID,
                cu.CustNo AS IstaAccountNumber ,
	--p.PremNo,
                cai.ClientAccountNo AS CNumber ,
                l.LDCName AS LDC ,
                iac.IAPlan ,
                iac.IAPoints ,
                @enddate AS EndDate ,
                p.BeginServiceDate AS EffectiveDate ,
	--p.EndServiceDate,
	--c.DateFrom,
	--c.DateTo,
	--c.CreateDate,
	--c.RequestID,
                c.InvoiceID ,
                SUM(cd.ConsDetQty) Usage ,
                uu.Unit
	/*case when cr.RBLRequestID IS Not null then 'R' End as RebillFlag,
	case when cr2.XRequestID IS Not null then 'X' End as CancelFlag,
	case when rr.InvoiceID IS not null then 'N'	End as RBLNewCycleFlag*/
        INTO    #MEICONS
        FROM    Stream.dbo.Meter m
        LEFT JOIN Stream.dbo.Consumption c ON c.MeterID = m.MeterID
        LEFT JOIN Stream.dbo.ConsumptionDetail cd ON cd.ConsId = c.ConsID
--	AND cd.ConsUnitID IN  (5, 9, 13)
        LEFT JOIN Stream.dbo.Premise p ON p.PremID = m.PremID
        LEFT JOIN Stream.dbo.LDCLookup l ON p.LDCID = l.LDCID
        LEFT JOIN Stream.dbo.Customer cu ON cu.CustID = p.CustID
        LEFT JOIN Stream.dbo.ConsumptionUnit uu ON uu.ConsUnitID = cd.ConsUnitID
        LEFT JOIN Stream.dbo.CustomerAdditionalInfo cai ON cai.CustID = cu.CustID
        LEFT JOIN Stream.dbo.IndependentAgentCustomer iac ON iac.CustID = cu.CustID
--left join #cancelrebill cr on c.RequestID = cr.RBLRequestID	
--left join #cancelrebill cr2 on c.RequestID = cr2.XRequestID	
--left join #RBLNewCycleUsg rr on rr.InvoiceID = c.InvoiceID
        WHERE   --year(c.CreateDate) = YEAR(@enddate) and MONTH(c.CreateDate) = MONTH(@enddate) 
                c.CreateDate BETWEEN @StartOfMonth
                             AND     @EndOfMonth
                AND cd.ConsUnitID IN ( 5 , 9 , 13 )
--and c.RequestID in (select cr.RBLRequestID from #cancelrebill cr)
--and cu.CustID = '97181'--'82949'--'100428' --[TODO: get rid of zero usage greater than premise enddate for custid 97181]
--and cu.CustNo = '3000232932'--'3000188281'--'3000125515'
GROUP BY 	
	--m.PremID,
	--cu.CustID,
                cu.CustNo ,
	--p.PremNo,
                cai.ClientAccountNo ,
                iac.IAPlan ,
                iac.IAPoints ,
                l.LDCName ,
                p.BeginServiceDate ,	
	--p.EndServiceDate,
	--c.DateFrom,
	--c.DateTo,
	--c.CreateDate,
	--c.RequestID,
                c.InvoiceID ,
                uu.Unit
	/*case when cr.RBLRequestID IS Not null then 'R' End, 
	case when cr2.XRequestID IS Not null then 'X' End,
	case when rr.InvoiceID IS not null then 'N'	End */

        CREATE NONCLUSTERED INDEX #tixcancelrebill1
        ON #cancelrebill ([XRequestID])

        CREATE NONCLUSTERED INDEX #tixcancelrebill2
        ON #cancelrebill ([RBLRequestID])

--===================================
--create last MEI table
--===================================
        SELECT DISTINCT
                m.* ,
                ( SELECT DISTINCT
                            CASE WHEN cr.RBLRequestID IS NOT NULL THEN 'Y'
                            END
                  FROM      #cancelrebill cr
                  LEFT JOIN Stream.dbo.Consumption cc ON cr.RBLRequestID = cc.RequestID
                  WHERE     cc.InvoiceID = m.InvoiceID
                ) REBILL ,
                ( SELECT DISTINCT
                            CASE WHEN cr2.XRequestID IS NOT NULL THEN 'Y'
                            END
                  FROM      #cancelrebill cr2
                  LEFT JOIN Stream.dbo.Consumption cc2 ON cr2.XRequestID = cc2.RequestID
                  WHERE     cc2.InvoiceID = m.InvoiceID
                ) CANCEL ,
                ( SELECT DISTINCT
                            CASE WHEN rr.InvoiceID IS NOT NULL THEN 'Y'
                            END
                  FROM      #RBLNewCycleUsg rr
                  WHERE     rr.InvoiceID = m.InvoiceID
                ) REBILL_NEWCYCLE
        INTO    #MEIFinal
        FROM    #meicons m

-- ******* MEI Report to be consumed by DPI ****************
--select * from #MEIFinal ff
--where ff.REBILL is not null and ff.CANCEL is not null
--where ((ff.REBILL is null and ff.CANCEL is null) or ff.REBILL_NEWCYCLE is not null) --> Pay MEI
--and ff.IstaAccountNumber = '3000203056'--'3000047881'


--************************* THE END! ***************************************

--========================================
--get meterID, premID
--========================================
--drop table #multiple
        SELECT DISTINCT
                f.* ,
                p.PremID ,
                m.MeterID ,
                m.MeterNo
        INTO    #multiple
        FROM    #MEIFinal f
        LEFT JOIN Stream.dbo.Consumption c ON f.InvoiceID = c.InvoiceID
        LEFT JOIN Stream.dbo.Meter m ON c.MeterID = m.MeterID
        LEFT JOIN Stream.dbo.ConsumptionDetail cd ON cd.ConsId = c.ConsID
        LEFT JOIN Stream.dbo.ConsumptionUnit cu ON cd.ConsUnitID = cu.ConsUnitID
        LEFT JOIN Stream.dbo.Premise p ON p.PremID = m.PremID
        LEFT JOIN Stream.dbo.Customer cc ON cc.CustID = p.CustID

--========================================
--find those with multiple meters
--========================================
--drop table #multiInvMeter
        SELECT  m.IstaAccountNumber ,
                COUNT(DISTINCT m.PremID) PremID ,
                COUNT(DISTINCT m.MeterID) MeterID ,
                COUNT(DISTINCT m.InvoiceID) InvoiceID
        INTO    #multiInvMeter
        FROM    #multiple m
        WHERE   ( ( m.REBILL IS NULL
                    AND m.CANCEL IS NULL
                  )
                  OR m.REBILL_NEWCYCLE IS NOT NULL
                ) --> Pay MEI
--and m.IstaAccountNumber = '3000067204'
GROUP BY        m.IstaAccountNumber
        HAVING  COUNT(DISTINCT m.PremID) > 1
                OR COUNT(DISTINCT m.MeterID) > 1
                OR COUNT(DISTINCT m.InvoiceID) > 1


--=================================
--these are the good ones: 
--=================================
--(1) multi meters same invoice
--(2) one meter multi invoices
/*
select * from #multiInvMeter m
where (m.InvoiceID = 1
or(m.MeterID = 1 and m.InvoiceID > 1))
*/

--=================================
--these are the BAD ones!!!! 
--=================================
/*
select * 
from #multiInvMeter mm
--left join #MEIFinal f on mm.IstaAccountNumber = f.IstaAccountNumber 
where mm.IstaAccountNumber not in
	(select m.IstaAccountNumber from #multiInvMeter m
	where m.InvoiceID = 1
	or(m.MeterID = 1 and m.InvoiceID > 1))
order by mm.InvoiceID desc
*/

--=================================
--fix BAD ones!! group by custno and rebill_newcycle (6630 row(s) affected)
--=================================
--drop table #rollup
        SELECT  mm.IstaAccountNumber ,
                mm.InvoiceID ,
                mm.MeterID ,
                mm.PremID ,
                m.Unit ,
                m.REBILL_NEWCYCLE ,
                i.ServiceFrom ,
                i.ServiceTo ,
                COUNT(DISTINCT m.InvoiceID) inv_cnt
        INTO    #rollup
        FROM    #multiInvMeter mm
        LEFT JOIN #MEIFinal m ON mm.IstaAccountNumber = m.IstaAccountNumber
        LEFT JOIN Stream.dbo.Invoice i ON m.InvoiceID = i.InvoiceID
        WHERE   mm.IstaAccountNumber NOT IN (
                SELECT  m.IstaAccountNumber
                FROM    #multiInvMeter m
                WHERE   m.InvoiceID = 1
                        OR ( m.MeterID = 1
                             AND m.InvoiceID > 1
                           ) )
                AND ( ( m.REBILL IS NULL
                        AND m.CANCEL IS NULL
                      )
                      OR m.REBILL_NEWCYCLE IS NOT NULL
                    ) --> Pay MEI	
GROUP BY        mm.IstaAccountNumber ,
                mm.InvoiceID ,
                mm.MeterID ,
                mm.PremID ,
                m.Unit ,
                m.REBILL_NEWCYCLE ,
                i.ServiceFrom ,
                i.ServiceTo
        ORDER BY COUNT(DISTINCT m.InvoiceID) ,
                mm.IstaAccountNumber

--=================================
--these are resolved
--=================================
--drop table #resolved
        SELECT  *
        INTO    #resolved
        FROM    #rollup rr
        WHERE   rr.IstaAccountNumber IN ( SELECT    r.IstaAccountNumber
                                          FROM      #rollup r
                                          GROUP BY  r.IstaAccountNumber
                                          HAVING    COUNT(*) = 1 )
        ORDER BY rr.IstaAccountNumber

--============================================================
--go flag this is #MEIFinal (130281 row(s) affected) 
--select count(*) from #MEIFinalSum s where s.servicefrom is not null
--select * from #resolved
--============================================================
--drop table #MEIFinalSum
        SELECT DISTINCT
                m.* ,
                r.ServiceFrom ,
                r.ServiceTo
        INTO    #MEIFinalSum
        FROM    #MEIFinal m
        LEFT JOIN Stream.dbo.Invoice i ON i.InvoiceID = m.InvoiceID
        LEFT JOIN #resolved r ON m.IstaAccountNumber = r.IstaAccountNumber
                                 AND i.ServiceFrom = r.ServiceFrom
                                 AND i.ServiceTo = r.ServiceTo
                                 AND m.Unit = r.Unit
                                 AND ISNULL(m.REBILL_NEWCYCLE , 'N') = ISNULL(r.REBILL_NEWCYCLE ,
                                                              'N')
        WHERE   ( ( m.REBILL IS NULL
                    AND m.CANCEL IS NULL
                  )
                  OR m.REBILL_NEWCYCLE IS NOT NULL
                ) --> Pay MEI
--and m.IstaAccountNumber in ('3000002775','3000067204') 
ORDER BY        m.IstaAccountNumber


--select * from #resolved order by REBILL_NEWCYCLE
--select * from ##tuned
--(131710 row(s) affected)
--(3196 row(s) affected) + (125318 row(s) affected)
--============================================================
-- Here's the final result for DPI ***** THE END***********
--============================================================
--drop table #MEIFinalFinal
        SELECT  ff.IstaAccountNumber ,
                ff.CNumber ,
                ff.LDC ,
                ff.IAPlan ,
                ff.IAPoints ,
                ff.EndDate ,
                ff.EffectiveDate ,
                ff.Unit ,
                ff.REBILL ,
                ff.CANCEL ,
                ff.REBILL_NEWCYCLE ,
                s.ServiceFrom ,
                s.ServiceTo ,
                CAST(MIN(DISTINCT ff.InvoiceID) AS VARCHAR(10)) + ':'
                + CAST(COUNT(DISTINCT ff.InvoiceID) AS VARCHAR(3)) AS InvoiceID
--min(distinct ff.InvoiceID) as InvoiceID,COUNT(distinct ff.InvoiceID) as CountInvoiceID
                ,
                SUM(ff.Usage) Usage
        INTO    #MEIFinalFinal
        FROM    #MEIFinal ff
        LEFT JOIN #MEIFinalSum s ON ff.InvoiceID = s.InvoiceID
                                    AND ff.IstaAccountNumber = s.IstaAccountNumber
        WHERE   s.ServiceFrom IS NOT NULL
        GROUP BY ff.IstaAccountNumber ,
                ff.CNumber ,
                ff.LDC ,
                ff.IAPlan ,
                ff.IAPoints ,
                ff.EndDate ,
                ff.EffectiveDate ,
                ff.Unit ,
                ff.REBILL ,
                ff.CANCEL ,
                ff.REBILL_NEWCYCLE ,
                s.ServiceFrom ,
                s.ServiceTo
        UNION ALL
        SELECT  ff.IstaAccountNumber ,
                ff.CNumber ,
                ff.LDC ,
                ff.IAPlan ,
                ff.IAPoints ,
                ff.EndDate ,
                ff.EffectiveDate ,
                ff.Unit ,
                ff.REBILL ,
                ff.CANCEL ,
                ff.REBILL_NEWCYCLE ,
                s.ServiceFrom ,
                s.ServiceTo ,
                CAST(ff.InvoiceID AS VARCHAR(10)) AS InvoiceID ,
/*COUNT(distinct ff.InvoiceID) as CountInvoiceID,*/
                ff.Usage
--into #MEIRollup 
        FROM    #MEIFinal ff
        LEFT JOIN #MEIFinalSum s ON ff.InvoiceID = s.InvoiceID
                                    AND ff.IstaAccountNumber = s.IstaAccountNumber
        WHERE   s.ServiceFrom IS NULL
        GROUP BY ff.IstaAccountNumber ,
                ff.CNumber ,
                ff.LDC ,
                ff.IAPlan ,
                ff.IAPoints ,
                ff.EndDate ,
                ff.EffectiveDate ,
                ff.Unit ,
                ff.REBILL ,
                ff.CANCEL ,
                ff.REBILL_NEWCYCLE ,
                s.ServiceFrom ,
                s.ServiceTo ,
                ff.InvoiceID ,
                ff.Usage


        SELECT  *
        FROM    #MEIFinalFinal f 
--134793

--select * from #MEIFinal f where f.IstaAccountNumber = '3000150109'
--=================================
--account not rolled up....
--=================================
/*
select * from #rollup rr where rr.IstaAccountNumber in
(select r.IstaAccountNumber from #rollup r group by r.IstaAccountNumber having COUNT(*) > 1)
order by rr.IstaAccountNumber
*/

--=================================
--view account not rolled up....
--=================================
/*
select * from #MEIFinalFinal f 
where f.IstaAccountNumber = '3000070769'--'3000010223'--'3000176732'
and ((f.REBILL is null and f.CANCEL is null) or f.REBILL_NEWCYCLE is not null) --> Pay MEI
*/


        DROP TABLE #RBLNewCycle
        DROP TABLE #usage
        DROP TABLE #MEICONS
        DROP TABLE #RBLNewCycleUsg
        DROP TABLE #meifinal
        DROP TABLE #cancelrebill

        DROP TABLE #multiple
        DROP TABLE #multiInvMeter
        DROP TABLE #rollup
        DROP TABLE #resolved
        DROP TABLE #MEIFinalSum
        DROP TABLE #MEIFinalFinal


--select distinct ff.CANCEL, ff.REBILL, ff.REBILL_NEWCYCLE from #MEIFinalFinal ff

    END





GO


