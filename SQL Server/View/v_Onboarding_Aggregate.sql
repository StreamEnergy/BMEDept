USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Onboarding_Aggregate]    Script Date: 08/26/2014 15:12:11 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
				  
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_Onboarding_Aggregate]
AS
    SELECT  ONBRD.SPE_NAME ,
            ONBRD.DateLink ,
            ONBRD.SIGNUP_DATE ,
            ONBRD.SIGNUP_TYPE ,
            SUM(ONBRD.SIGNUP_CNT) SIGNUP_CNT ,
            SUM(ONBRD.SIGNUP_COMPLETE_CNT) SIGNUP_COMPLETE_CNT ,
            SUM(ONBRD.EXIT_ENROLL_WITHDRAWN_CNT) EXIT_ENROLL_WITHDRAWN_CNT ,
            SUM(ONBRD.EXIT_PENDING_CNT) EXIT_PENDING_CNT ,
            SUM(ONBRD.EXIT_QC_CALLS_INITIATED_CNT) EXIT_QC_CALLS_INITIATED_CNT ,
            SUM(ONBRD.EXIT_QC_INITIATED_CNT) EXIT_QC_INITIATED_CNT ,
            SUM(ONBRD.EXIT_STREAM_CANCEL_CNT) EXIT_STREAM_CANCEL_CNT ,
            SUM(ONBRD.EXIT_UTILITY_CANCEL_CNT) EXIT_UTILITY_CANCEL_CNT ,
            SUM(ONBRD.EXIT_UTILITY_REJECT_CNT) EXIT_UTILITY_REJECT_CNT ,
            SUM(ONBRD.EXIT_OUTBOUND_QC_EXHAUSTED_CNT) EXIT_OUTBOUND_QC_EXHAUSTED_CNT ,
            SUM(ONBRD.EXIT_ENROLL_CNT) EXIT_ENROLL_CNT
    FROM    ( SELECT    CONVERT(VARCHAR(10) , ec.createdate , 101) AS DateLink ,
                        CONVERT(VARCHAR(10) , ec.createdate , 101) AS 'SIGNUP_DATE' ,
                        CASE WHEN ec.EnrollStatusID = '2'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'SIGNUP_COMPLETE_CNT' ,
                        CASE WHEN ec.EnrollStatusID = '4'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_WITHDRAWN_CNT' ,
                        CASE WHEN ec.EnrollStatusID IN ( '16' , '17' , '18' ,
                                                         '19' , '20' , '21' )
                                  AND p.StatusID IS NULL THEN 1
                             WHEN p.StatusID = '0' THEN 1
                             ELSE 0
                        END AS 'EXIT_PENDING_CNT' ,
                        CASE WHEN ec.EnrollStatusID = '9'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_CALLS_INITIATED_CNT' ,
                        CASE WHEN ec.EnrollStatusID IN ( '5' , '6' , '7' , '8' ,
                                                         '10' , '11' , '12' ,
                                                         '13' , '14' )
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_INITIATED_CNT' ,
                        CASE WHEN p.StatusID = 3 --in (5,6,11) 
					--and t.StatusCode = 'EB3' 
                                  AND t.Direction = '0' THEN 1
                             ELSE 0
                        END AS 'EXIT_STREAM_CANCEL_CNT' ,
                        CASE WHEN p.StatusID = 3 --in (5,6,11) 
					--and t.StatusCode = 'EB3' 
                                  AND ( t.Direction = '1'
                                        OR T.Direction IS NULL
                                      ) THEN 1  
			 --WHEN p.StatusID = '3'
				--THEN 1
                             ELSE 0
                        END AS 'EXIT_UTILITY_CANCEL_CNT' ,
                        CASE p.StatusID
                          WHEN 2 THEN 1
                          WHEN 4 THEN 1
                          ELSE 0
                        END AS 'EXIT_UTILITY_REJECT_CNT' ,
                        CASE WHEN ec.EnrollStatusID IS NOT NULL THEN 1
                             ELSE 0
                        END AS 'SIGNUP_CNT' ,
                        CASE ss.salesourcedescription
                          WHEN 'ignite' THEN 'Ignite Websites'
                          WHEN 'call' THEN 'Telephonic'
                          WHEN 'paper' THEN 'LOA'
                          WHEN 'stream' THEN 'Streamenergy.net'
                          ELSE 'Other'
                        END AS 'SIGNUP_TYPE' ,
                        CASE WHEN ec.EnrollStatusID = '15'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_OUTBOUND_QC_EXHAUSTED_CNT' ,
                        m.STATE AS 'SPE_NAME' ,
                        CASE WHEN p.StatusID IN ( '1' , '7' , '8' , '9' , '10' )
                             THEN 1
                             WHEN p.StatusID IN ( '5' , '6' , '11' ) /*and (t.StatusCode <> 'EB3' or t.StatusCode IS null)*/
                             THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_CNT'
              FROM      Stream.dbo.enrollcustomer AS ec
              LEFT JOIN Stream.dbo.EnrollCustomerPremise ecp ON ec.EnrollCustID = ecp.EnrollCustID
                                                              AND ecp.DeletedFlag = 0
              LEFT JOIN Stream.dbo.enrollstatus AS es ON es.enrollstatusid = ec.EnrollStatusID
              LEFT JOIN Stream.dbo.salesource AS ss ON ss.salesourceid = ec.salessourceid
              LEFT JOIN Stream.dbo.Customer c ON ec.CsrCustID = c.CustID
              LEFT JOIN Stream.dbo.Premise p ON c.CustID = p.CustID
              LEFT JOIN Stream.dbo.LDCLookup l ON l.LDCID = ecp.TDSP
              LEFT JOIN StreamInternal.dbo.Market m ON l.MarketID = m.MarketID
              LEFT JOIN --*** get max drop trxn for customer in Drop Pending (5), 
		--*** Drop Accepted (6) and Inactive (7) premise status.
                        ( SELECT    ctr.requestid ,
                                    ctr.custid ,
                                    r.ServiceActionCode ,
                                    r.StatusCode ,
                                    r.direction
                          FROM      ( SELECT    MAX(t.requestid) AS requestid ,
                                                t.custid
                                      FROM      Stream.dbo.customertransactionrequest t
                                      JOIN      Stream.dbo.Premise p ON t.CustID = p.CustID
                                      WHERE     p.StatusID = 3 --in (5,6,11) 
                                                AND t.TransactionType = '814'
                                                AND t.ActionCode = 'D'
                                                AND t.ServiceActionCode IN (
                                                'Q' , '7' )
                                      GROUP BY  t.custid
                                    ) ctr
                          JOIN      Stream.dbo.customertransactionrequest r ON ctr.requestid = r.requestid
                        ) t ON t.CustID = c.CustID
              WHERE     es.enrollstatusid NOT IN ( 3 , 1 )
            ) ONBRD
    GROUP BY ONBRD.SPE_NAME ,
            ONBRD.DateLink ,
            ONBRD.SIGNUP_DATE ,
            ONBRD.SIGNUP_TYPE









GO


