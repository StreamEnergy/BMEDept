USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Customer_Profile_Load_CIS1_TX]    Script Date: 08/25/2014 09:52:18 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
10/14/2013				Darren, Williams					This SP is for the ISTA Aging Report. To run the queries that ISTA gave us.
10/14/2013				Darren Williams						Initial Release [sp_Customer_Profile_Load_CIS1_TX] .
															Purpose of this SP is for the Daily Billing Report. To run the queries that ISTA gave us.
02/17/2014				Darren Williams						This is the updated version that cleans the data for TX			
02/24/2014				Darren Williams						Add TX scenario 6 validation		
3/14/2014				Darren Williams						Added transaction and email for validation		 
4/14/2014				Darren Williams						Check to see if delay in qvw  					   
08/15/2014 				Jide Akintoye						Format Stored procedure




**********************************************************************************************/

CREATE PROCEDURE [dbo].[sp_Customer_Profile_Load_CIS1_TX]
AS
    BEGIN



----------------------------------
--get enrollment
----------------------------------
        SELECT DISTINCT
                t.BeginServiceDate ,
                t.enroll_orig_transaction_id ,
                t.CustNo ,
                t.PremNo ,
                t.RecordDate
        INTO    #enroll
        FROM    CustomerProfile_TX t --where t.PremNo in ('10443720008501695','10176990006104570')

----------------------------------
--get drop
----------------------------------
        SELECT DISTINCT
                t.EndServiceDate ,
                t.drop_sender_transaction_id ,
                t.CustNo ,
                t.PremNo
        INTO    #drop
        FROM    CustomerProfile_TX t --where t.PremNo in ('10443720008501695','10176990006104570')

----------------------------------
--get begin/end date
----------------------------------
        SELECT  sub.*
--case when  CONVERT(VARCHAR(10), sub.RecordDate, 120) between sub.BeginServiceDate and isnull(sub.EndServiceDate,'12/31/2999')
--	then 'Y' else 'N' end as OnFlow
        INTO    #TX
        FROM    ( SELECT    e.* ,
                            d.CustNo AS DropCustNo ,
                            d.EndServiceDate ,
                            d.drop_sender_transaction_id ,
                            ROW_NUMBER() OVER ( PARTITION BY e.enroll_orig_transaction_id ORDER BY d.EndServiceDate ASC ) 'rowversion'
                  FROM      #enroll e
                  LEFT JOIN #drop d ON e.PremNo = d.PremNo
                                       AND e.BeginServiceDate < d.EndServiceDate
                ) sub
        WHERE   sub.rowversion = '1' --and sub.PremNo = '10176990006104570' 
ORDER BY        sub.PremNo ,
                sub.BeginServiceDate


/**************esiid no longer belongs to this customer crap*******************************
**********************************************************************************************/
        SELECT  e.* ,
                d.CustNo AS DropCustNo ,
                d.EndServiceDate ,
                d.drop_sender_transaction_id ,
                ROW_NUMBER() OVER ( PARTITION BY e.enroll_orig_transaction_id ORDER BY d.EndServiceDate ASC ) 'rowversion'
        INTO    #enroll_sort
        FROM    #enroll e
        LEFT JOIN #drop d ON e.PremNo = d.PremNo
                             AND e.BeginServiceDate < d.EndServiceDate

-------------------------------
--get max serv date from invoice data
-------------------------------
        SELECT /*i.customer_number,*/
                i.esiid ,
                MAX(i.max_serv_end_datemin_invoice_id) AS max_serv_end_date
        INTO    #inv
        FROM    tmp_MktRch_Contract_Invoice i
        GROUP BY /*i.customer_number,*/ i.esiid 


---------------------------------
--fix these enddate (snapshot active on recorddate) (1279 row(s) affected)
--------------------------------
--(339,606 row(s) affected)
        SELECT DISTINCT
                t.CustNo ,
                t.PremNo ,
                t.enroll_orig_transaction_id ,
                t.BeginServiceDate ,
                t.EndServiceDate ,
                i.max_serv_end_date ,
                DATEDIFF(DAY , t.BeginServiceDate , i.max_serv_end_date) AS DiffDay ,
                CONVERT(VARCHAR(10) , t.RecordDate - 90 , 101) AS CutOffDate
        INTO    #TXFix
        FROM    #TX t
        LEFT JOIN #inv i ON i.esiid = t.PremNo
        WHERE   CONVERT(VARCHAR(10) , t.RecordDate , 101) BETWEEN t.BeginServiceDate
                                                          AND ISNULL(t.EndServiceDate ,
                                                              '12/31/2999') --> onflow on recorddate
                AND ( i.max_serv_end_date < CONVERT(VARCHAR(10) , t.RecordDate
                      - 90 , 101) )--or i.max_serv_end_date is null) TODO HERE!!!
                AND t.BeginServiceDate < CONVERT(VARCHAR(10) , t.RecordDate
                - 90 , 101)
                AND ( t.BeginServiceDate <= i.max_serv_end_date )--or i.max_serv_end_date is null)  TODO HERE!!!
--and t.PremNo = '10443720006813660'
ORDER BY        t.BeginServiceDate

-----------------------------
--update TX Count (1324107 row(s) affected)
-----------------------------
        SELECT DISTINCT
                t.CustNo ,
                t.BeginServiceDate ,
                t.PremNo ,
                t.RecordDate ,
                t.enroll_orig_transaction_id ,
                t.rowversion ,
                ISNULL(t.DropCustNo , f.CustNo) DropCustNo ,
                ISNULL(t.EndServiceDate , f.max_serv_end_date) EndServiceDate ,
                CASE WHEN f.max_serv_end_date IS NOT NULL
                     THEN 'MaxInvDate CutOff'
                     WHEN t.drop_sender_transaction_id IS NOT NULL
                     THEN t.drop_sender_transaction_id
                END AS drop_sender_transaction_id
        INTO    #TX_FINAL 
--ISNULL(f.max_serv_end_date, t.drop_sender_transaction_id) drop_sender_transaction_id,
--f.max_serv_end_date, f.CustNo as InvCustNo
        FROM    #TX t
        LEFT JOIN #TXFix f ON t.enroll_orig_transaction_id = f.enroll_orig_transaction_id
--where --f.enroll_orig_transaction_id is not null
--t.PremNo in
--('1008901014190311044100','10032789405025270','10032789405048590')

--------------------------------------
--get max serv_end_date
--------------------------------------
        SELECT  i.customer_number ,
                i.esiid ,
                MAX(i.max_serv_end_datemin_invoice_id) AS max_end_date ,
                MIN(i.min_serv_start_date) AS min_start_date
        INTO    #invmax
        FROM    tmp_MktRch_Contract_Invoice i
        GROUP BY i.customer_number ,
                i.esiid

-----------------------------------
--validation
-----------------------------------
        SELECT  t.CustNo ,
                t.BeginServiceDate ,
                t.PremNo ,
                t.RecordDate ,
                t.enroll_orig_transaction_id ,
                t.rowversion ,
--================
--EndServiceDate
--================
--scenario 1
                CASE WHEN i.max_end_date IS NULL
                          AND DATEDIFF(DAY , t.BeginServiceDate , GETDATE()) > 60
                     THEN t.BeginServiceDate 
--scenario 2
                     WHEN i.max_end_date IS NOT NULL
                          AND DATEDIFF(DAY , i.max_end_date , GETDATE()) > 90
                          AND t.EndServiceDate IS NULL THEN i.max_end_date
                     ELSE t.EndServiceDate
                END AS EndServiceDate ,
--================
--DropCustNo
--================
--scenario 1
                CASE WHEN i.max_end_date IS NULL
                          AND DATEDIFF(DAY , t.BeginServiceDate , GETDATE()) > 60
                     THEN t.CustNo 
--scenario 2
                     WHEN i.max_end_date IS NOT NULL
                          AND DATEDIFF(DAY , i.max_end_date , GETDATE()) > 90
                          AND t.EndServiceDate IS NULL THEN t.CustNo
                     ELSE t.DropCustNo
                END AS DropCustNo ,
--================
--drop_sender_transaction_id
--================
--scenario 1
                CASE WHEN i.max_end_date IS NULL
                          AND DATEDIFF(DAY , t.BeginServiceDate , GETDATE()) > 60
                     THEN 'scenario 1'
--scenario 2
                     WHEN i.max_end_date IS NOT NULL
                          AND DATEDIFF(DAY , i.max_end_date , GETDATE()) > 90
                          AND t.EndServiceDate IS NULL THEN 'scenario 2'
                     ELSE t.drop_sender_transaction_id
                END AS drop_sender_transaction_id ,
                i.max_end_date ,
                DATEDIFF(DAY , t.BeginServiceDate , GETDATE()) AS BeginServiceDateLapse ,
                DATEDIFF(DAY , i.max_end_date , GETDATE()) AS max_end_date_lapse ,
--================
--CaseNum
--================
--scenario 1
                CASE WHEN i.max_end_date IS NULL
                          AND DATEDIFF(DAY , t.BeginServiceDate , GETDATE()) > 60
                     THEN 'scenario 1'
--scenario 2
                     WHEN i.max_end_date IS NOT NULL
                          AND DATEDIFF(DAY , i.max_end_date , GETDATE()) > 90
                          AND t.EndServiceDate IS NULL THEN 'scenario 2'
                     ELSE 'trxn'
                END AS CaseNum
        INTO    #tx_final2
        FROM    #TX_FINAL t
        LEFT JOIN #invmax i ON t.CustNo = i.customer_number
                               AND i.esiid = t.PremNo

--==========================================
--get tx_final2 + scenario 3(invoiced, no enroll trxn) 
--==========================================
        SELECT  *
        INTO    #tx_final3
        FROM    #tx_final2
        UNION 
-------------------------------
--scenario 3: insert these records from invoice since trxn is messed up
-------------------------------
        SELECT  i.customer_number ,
                i.min_start_date ,
                i.esiid ,
                x.RecordDate ,
                MAX(y.enroll_orig_transaction_id) ,
                '1' ,
                CASE WHEN x.PremStatusID IN ( '04' , '06' ) THEN NULL
                     ELSE i.max_end_date
                END ,
                i.customer_number ,
                MAX(y.drop_sender_transaction_id) ,
                i.max_end_date ,
                9999 ,
                9999 ,
                'scenario 3'
        FROM    #tx_final2 t
        FULL OUTER JOIN #invmax i ON t.CustNo = i.customer_number
                                     AND t.PremNo = i.esiid
        LEFT JOIN CustomerProfile_TX y ON y.CustNo = i.customer_number
                                          AND y.PremNo = i.esiid
        LEFT JOIN CustomerProfile_Detail_TX x ON x.CustNo = i.customer_number
                                                 AND x.PremNo = i.esiid
        WHERE   t.CustNo IS NULL
                AND t.PremNo IS NULL --and x.PremStatus = '04'
--and i.esiid in ('10443720001549857','10032789400619640','10032789492601820')
GROUP BY        i.customer_number ,
                i.min_start_date ,
                i.esiid ,
                x.RecordDate ,
                i.max_end_date ,
                CASE WHEN x.PremStatusID IN ( '04' , '06' ) THEN NULL
                     ELSE i.max_end_date
                END


-------------------------------
--scenario 4: use max_end_date when: 
--				 (1) dups found in drop_sender_transaction_id and 
--				 (2) EndServiceDate > max_end_date
-------------------------------
        SELECT  t.* ,
                i.max_end_date AS max_end_date2 ,
                DATEDIFF(DAY , t.EndServiceDate , i.max_end_date) diff
        INTO    #scenario4
        FROM    #tx_final3 t
        LEFT JOIN #invmax i ON t.CustNo = i.customer_number
                               AND t.PremNo = i.esiid
        WHERE   DATEDIFF(DAY , t.EndServiceDate , i.max_end_date) < 0
                AND t.drop_sender_transaction_id IN (
                SELECT  tt.drop_sender_transaction_id
                FROM    #tx_final3 tt
                GROUP BY tt.drop_sender_transaction_id
                HAVING  COUNT(*) > 1 )
--DATEDIFF(DAY,t.EndServiceDate,i.max_end_date) > 90
--and t.PremNo = '10443720008208810'--'10443720009456009'--'1008901023809176910100'
ORDER BY        DATEDIFF(DAY , t.EndServiceDate , i.max_end_date) 

--=================================
-- update scenario 4
--=================================

        UPDATE  t
        SET     t.EndServiceDate = s.max_end_date2 ,
                t.CaseNum = 'scenario 4' ,
                t.drop_sender_transaction_id = 'scenario 4'
/*select distinct t.**/
        FROM    #tx_final3 t
        JOIN    #scenario4 s ON t.CustNo = s.CustNo
                                AND t.PremNo = s.PremNo
                                AND t.BeginServiceDate = s.BeginServiceDate
                                AND t.EndServiceDate = s.EndServiceDate
                                AND t.drop_sender_transaction_id = s.drop_sender_transaction_id
                                AND t.enroll_orig_transaction_id = s.enroll_orig_transaction_id

--=================================
--scenario 5 (1256 row(s) affected) 
--               use min_start_date when: 
--				 (1) dups found in enroll_orig_transaction_id and 
--				 (2) min_start_date > BeginServiceDate
--=================================
        SELECT  i.min_start_date ,
                t.* ,
                DATEDIFF(DAY , t.BeginServiceDate , i.min_start_date) diff
        INTO    #scenario5
        FROM    #tx_final3 t
        LEFT JOIN #invmax i ON t.CustNo = i.customer_number
                               AND t.PremNo = i.esiid
        WHERE   DATEDIFF(DAY , t.BeginServiceDate , i.min_start_date) > 0
                AND t.enroll_orig_transaction_id IN (
                SELECT  tt.enroll_orig_transaction_id
                FROM    #tx_final3 tt
                GROUP BY tt.enroll_orig_transaction_id
                HAVING  COUNT(*) > 1 )
--and t.PremNo = '1008901020150000412100'
ORDER BY        DATEDIFF(DAY , t.BeginServiceDate , i.min_start_date)

--=================================
-- update scenario 5
--=================================
 
        UPDATE  t
        SET     t.BeginServiceDate = s.min_start_date ,
                t.CaseNum = 'scenario 5'--, t.drop_sender_transaction_id = 'scenario 5'
/*select distinct t.**/
        FROM    #tx_final3 t
        JOIN    #scenario5 s ON t.CustNo = s.CustNo
                                AND t.PremNo = s.PremNo
                                AND t.BeginServiceDate = s.BeginServiceDate
                                AND ISNULL(t.EndServiceDate , '1/1/2999') = ISNULL(s.EndServiceDate ,
                                                              '1/1/2999')
                                AND ISNULL(t.drop_sender_transaction_id ,
                                           '999') = ISNULL(s.drop_sender_transaction_id ,
                                                           '999')
                                AND t.enroll_orig_transaction_id = s.enroll_orig_transaction_id

--=================================
-- scenario 6: [DONE!]
--=================================
--dups onflow custno
        SELECT  COUNT(DISTINCT t.custno) AS custno_cnt ,
                t.premno
        INTO    #dups
        FROM    #tx_final3 t
        WHERE   GETDATE() BETWEEN t.BeginServiceDate
                          AND     ISNULL(t.EndServiceDate , '12/31/2999') 
--and t.PremNo = '10176990007196855'
GROUP BY        t.premno
        HAVING  COUNT(t.premno) > 1
--drop table #dups

--10032789423460911 = this record should not be updated
--(163 row(s) affected)
        SELECT  ROW_NUMBER() OVER ( PARTITION BY t.premno ORDER BY t.premno, t.beginservicedate ASC ) rownum ,
                t.*
        INTO    #dups_premno
        FROM    #tx_final3 t
        WHERE   t.premno IN ( SELECT    premno
                              FROM      #dups d
                              WHERE     d.custno_cnt > 1 )
        ORDER BY t.premno ,
                t.beginservicedate

--drop table #dups_premno
--(43 row(s) affected)
/*============================================================
update EndServiceDate = max_end_date since the max_end_date 
is the same as the next BeginServiceDate for the same PremNo 
==============================================================*/
        SELECT  a.rownum ,
                a.CustNo ,
                a.PremNo ,
                a.BeginServiceDate ,
                a.EndServiceDate ,
                a.max_end_date ,
--b.rownum, b.CustNo, b.BeginServiceDate, b.EndServiceDate, b.max_end_date, 
                a.enroll_orig_transaction_id
        INTO    #scenario6
        FROM    #dups_premno a
        LEFT JOIN #dups_premno b ON a.rownum = b.rownum - 1
                                    AND a.PremNo = b.PremNo
                                    AND a.enroll_orig_transaction_id = b.enroll_orig_transaction_id
        WHERE   a.EndServiceDate IS NULL
                AND a.max_end_date = b.BeginServiceDate
                AND a.CustNo <> b.CustNo;

        UPDATE  t
        SET     t.EndServiceDate = s.max_end_date ,
                t.CaseNum = 'scenario 6'
        FROM    #tx_final3 t
        JOIN    #scenario6 s ON t.CustNo = s.CustNo
                                AND t.PremNo = s.PremNo
                                AND t.BeginServiceDate = s.BeginServiceDate
                                AND t.enroll_orig_transaction_id = s.enroll_orig_transaction_id

--select * from #dups_premno s where s.PremNo = '10032789423460911'
;

---------------------------------
--	Insert the final data
---------------------------------
        BEGIN TRY

            BEGIN TRANSACTION tx

            DELETE  FROM [StreamInternal].[dbo].[CustomerProfile]
            WHERE   [DataSource] = 'CIS1'; 

            INSERT  INTO [StreamInternal].[dbo].[CustomerProfile]
                    ( PremNo ,
                      CustNo ,
                      CustID ,
                      PremID ,
                      LDCNo ,
                      PremStatusID ,
                      PremStatus ,
                      BeginServiceDate ,
                      EndServiceDate ,
                      PremiseType ,
                      LDCID ,
                      LDCName ,
                      Market ,
                      Commodity ,
                      State ,
                      EnrollType ,
                      LossType ,
                      CurrentProduct ,
                      CurrentProductDesc ,
                      CurrentContractEndDate ,
                      CurrentContractRate ,
                      CurrentContractLength ,
                      FirstName ,
                      LastName ,
                      LastSSN ,
                      ServiceZip ,
                      Phone ,
                      CellPhone ,
                      WorkPhone ,
                      Email ,
                      OriginalStreamSignUpDate ,
                      CurrentPlanType ,
                      DataSource ,
                      RecordCreatedBy ,
                      RecordDate ,
                      RecordLastUpdatedBy ,
                      RecordLastUpdatedDate
	                )
                    SELECT DISTINCT
                            dtx.PremNo ,
                            dtx.CustNo ,
                            dtx.CustID ,
                            dtx.PremID ,
                            dtx.LDCNo ,
                            dtx.PremStatusID ,
                            dtx.PremStatus ,
                            t.BeginServiceDate ,
                            t.EndServiceDate ,
                            dtx.PremiseType ,
                            dtx.LDCID ,
                            dtx.LDCName ,
                            dtx.Market ,
                            CASE WHEN dtx.Commodity IS NULL THEN 'Elec'
                                 ELSE dtx.Commodity
                            END AS Commodity ,       
	  --dtx.Commodity,
                            CASE WHEN dtx.State IS NULL THEN 'TX'
                                 ELSE dtx.State
                            END AS State ,
      -- dtx.State,
                            tx.EnrollType ,
                            MAX(tx.LossType) AS LossType ,
                            dtx.CurrentProduct ,
                            dtx.CurrentProductDesc ,
                            dtx.CurrentContractEndDate ,
                            dtx.CurrentContractRate ,
                            dtx.CurrentContractLength ,
                            dtx.FirstName ,
                            dtx.LastName ,
                            dtx.LastSSN ,
                            dtx.ServiceZip ,
                            dtx.Phone ,
                            dtx.CellPhone ,
                            dtx.WorkPhone ,
                            dtx.Email ,
                            dtx.OriginalStreamSignUpDate ,
                            dtx.CurrentPlanType ,
                            CASE WHEN dtx.DataSource IS NULL THEN 'CIS1'
                                 ELSE dtx.DataSource
                            END AS DataSource ,
                            CASE WHEN dtx.RecordCreatedBy IS NULL
                                 THEN 'TX Counts_SSIS.qvw'
                                 ELSE dtx.RecordCreatedBy
                            END AS RecordCreatedBy ,
                            CASE WHEN dtx.RecordDate IS NULL
                                 THEN ( SELECT  MIN(RecordDate)
                                        FROM    [StreamInternal].[dbo].CustomerProfile_TX
                                        WHERE   [DataSource] = 'CIS1'
                                      )
                                 ELSE dtx.RecordDate
                            END AS RecordDate ,
                            CASE WHEN dtx.RecordLastUpdatedBy IS NULL
                                 THEN 'SSIS_AllData.dtsx'
                                 ELSE dtx.RecordLastUpdatedBy
                            END AS RecordLastUpdatedBy ,
                            CASE WHEN dtx.RecordLastUpdatedDate IS NULL
                                 THEN GETDATE()
                                 ELSE dtx.RecordLastUpdatedDate
                            END AS RecordLastUpdatedDate
                    FROM    #tx_final3 t
                    LEFT JOIN CustomerProfile_TX tx ON t.CustNo = tx.CustNo
                                                       AND t.PremNo = tx.PremNo
                                                       AND t.enroll_orig_transaction_id = tx.enroll_orig_transaction_id
            --and  isnull(t.drop_sender_transaction_id,'9999')  =  isnull(tx.drop_sender_transaction_id,'9999')   
                    LEFT JOIN CustomerProfile_TX txx ON t.CustNo = txx.CustNo
                                                        AND t.PremNo = txx.PremNo
                                                        AND ISNULL(t.drop_sender_transaction_id ,
                                                              '9999') = ISNULL(txx.drop_sender_transaction_id ,
                                                              '9999')
                    FULL OUTER JOIN CustomerProfile_Detail_TX dtx ON t.CustNo = dtx.CustNo
                                                              AND t.PremNo = dtx.PremNo
          
      --and t.drop_sender_transaction_id = tx.drop_sender_transaction_id
      -- where GETDATE() between t.BeginServiceDate and isnull(t.EndServiceDate,'12/31/2999') 
       --and  t.Premno = '10032789400002410'
                    GROUP BY dtx.PremNo ,
                            dtx.CustNo ,
                            dtx.CustID ,
                            dtx.PremID ,
                            dtx.LDCNo ,
                            dtx.PremStatusID ,
                            dtx.PremStatus ,
                            dtx.PremStatus ,
                            t.BeginServiceDate ,
                            t.EndServiceDate ,
                            dtx.PremiseType ,
                            dtx.LDCID ,
                            dtx.LDCName ,
                            dtx.Market ,
                            dtx.Commodity ,
                            dtx.State ,
                            tx.EnrollType ,  --tx.LossType, 
                            dtx.CurrentProduct ,
                            dtx.CurrentProductDesc ,
                            dtx.CurrentContractEndDate ,
                            dtx.CurrentContractRate ,
                            dtx.CurrentContractLength ,
                            dtx.FirstName ,
                            dtx.LastName ,
                            dtx.LastSSN ,
                            dtx.ServiceZip ,
                            dtx.Phone ,
                            dtx.CellPhone ,
                            dtx.WorkPhone ,
                            dtx.Email ,
                            dtx.OriginalStreamSignUpDate ,
                            dtx.CurrentPlanType ,
                            dtx.DataSource ,
                            dtx.RecordCreatedBy ,
                            dtx.RecordDate ,
                            dtx.RecordLastUpdatedBy ,
                            dtx.RecordLastUpdatedDate
                    ORDER BY dtx.PremNo   

            IF @@TRANCOUNT > 0
                BEGIN --SUCCESS, nothing failed, now I can commit!!
                    COMMIT TRANSACTION tx;    -- now everything is committed
                END
      --SET @IsError = @@ERROR
      
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                BEGIN
                    ROLLBACK TRANSACTION tx;
                    EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
                        @from_address = 'SSIS_AllData@streamenergy.net' ,
                        @recipients = 'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net' ,
                        @subject = 'Error in sp_Customer_Profile_Load_CIS1_TX' ,
                        @body = 'There was error on insert data into CustomerProfile in sp_Customer_Profile_Load_CIS1_TX' ,
                        @body_format = 'HTML';        
                END

	--SELECT @IsError = 1, @ErrorMessage = 'Exception message: ' +  Cast (Error_Message() as varchar)  + ';'
	--SELECT @ErrorMessage = 'FAILED - second insert did not populate'
        
        END CATCH;      
      
      --select * from CustomerProfile_TX_Test t
      --where t.Premno = '10032789400014060'
      
      --select * from CustomerProfile_Detail_TX_Test t where t.Premno = '10032789400014060'
	 ---------------------------------    
		--select * FROM  [StreamInternal].[dbo].[CustomerProfile_Test]
		--WHERE [DataSource] = 'CIS1'
	 ---------------------------------
	 
        DROP TABLE #enroll
        DROP TABLE #drop
        DROP TABLE #enroll_sort
        DROP TABLE #TX
        DROP TABLE #inv
        DROP TABLE #TXFix
        DROP TABLE #TX_FINAL
        DROP TABLE #tx_final3
        DROP TABLE #tx_final2
        DROP TABLE #invmax
        DROP TABLE #scenario4
        DROP TABLE #scenario5
        DROP TABLE #scenario6
        DROP TABLE #dups
        DROP TABLE #dups_premno
	
	
---------------------------------
--	Validate data if bad send email
---------------------------------	
        DECLARE @tableHTML NVARCHAR(MAX);
        DECLARE @RecordDate AS DATE;
		
        SET @RecordDate = CONVERT(VARCHAR(10) , ( SELECT    MIN(RecordDate)
                                                  FROM      [StreamInternal].[dbo].CustomerProfile
                                                  WHERE     [DataSource] = 'CIS1'
                                                ) , 110);
	
        IF @RecordDate <= CONVERT(VARCHAR(10) , GETDATE() - 2 , 110)
            BEGIN
                SET @tableHTML = N'<br>'
                    + N'The Customer Profile for TX does not have latest data, please check in sp_Customer_Profile_Load_CIS1_TX or TX_Counts_SSIS.qvw'
                    + N'TX data is more than 2 days old.  It should only be 1 day since it is run on 9pm the previous day.'
                    + N'<br><br><br>' + N'<table>'
                    + N'<caption><H1>Counts Report</H1></caption>'
                    + N'<table border="1">'
                    + N'<tr><th>Counts</th><th>RecordDate</th>'
                    + N'<th>DataSource</th><th>RecordCreatedBy</th></tr>'
                    + CAST(( SELECT td = COUNT(*) ,
                                    '' ,
                                    td = c.RecordDate ,
                                    '' ,
                                    td = c.DataSource ,
                                    '' ,
                                    td = c.RecordCreatedBy ,
                                    ''
                             FROM   StreamInternal.dbo.CustomerProfile c
                             WHERE  [DataSource] = 'CIS1'
                             GROUP BY c.DataSource ,
                                    c.RecordDate ,
                                    c.RecordCreatedBy
                           FOR
                             XML PATH('tr') ,
                                 TYPE
                           ) AS NVARCHAR(MAX)) + N'</table>';

                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
                    @from_address = 'LoadCustomerProfile@streamenergy.net' ,
                    @recipients = 'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net' ,
                    @subject = 'Error in Customer Profile for TX' ,
                    @body = @tableHTML , @body_format = 'HTML';
            END	
	
		--Check to see if delay in qvw
        SET @RecordDate = CONVERT(VARCHAR(10) , ( SELECT    MAX(RecordDate)
                                                  FROM      [StreamInternal].[dbo].CustomerProfile
                                                  WHERE     [DataSource] = 'CIS1'
                                                ) , 110);
	
        IF @RecordDate = CONVERT(VARCHAR(10) , GETDATE() , 110)
            BEGIN
                SET @tableHTML = N'<br>'
                    + N'The Customer Profile for TX had a delay in latest data, please check in sp_Customer_Profile_Load_CIS1_TX or TX_Counts_SSIS.qvw'
                    + N'TX current data is not correct.  The qvw was delayed is processing.'
                    + N'<br><br><br>' + N'<table>'
                    + N'<caption><H1>Counts Report</H1></caption>'
                    + N'<table border="1">'
                    + N'<tr><th>Counts</th><th>RecordDate</th>'
                    + N'<th>DataSource</th><th>RecordCreatedBy</th></tr>'
                    + CAST(( SELECT td = COUNT(*) ,
                                    '' ,
                                    td = c.RecordDate ,
                                    '' ,
                                    td = c.DataSource ,
                                    '' ,
                                    td = c.RecordCreatedBy ,
                                    ''
                             FROM   StreamInternal.dbo.CustomerProfile c
                             WHERE  [DataSource] = 'CIS1'
                             GROUP BY c.DataSource ,
                                    c.RecordDate ,
                                    c.RecordCreatedBy
                           FOR
                             XML PATH('tr') ,
                                 TYPE
                           ) AS NVARCHAR(MAX)) + N'</table>';

                EXEC msdb.dbo.sp_send_dbmail @profile_name = 'SMTPRELAY01' ,
                    @from_address = 'LoadCustomerProfile@streamenergy.net' ,
                    @recipients = 'darren.williams@streamenergy.net;steve.nelson@streamenergy.net;mark.cheng@streamenergy.net;matt.baker@streamenergy.net' ,
                    @subject = 'Error in Customer Profile for TX' ,
                    @body = @tableHTML , @body_format = 'HTML';
            END	

    END






























GO


