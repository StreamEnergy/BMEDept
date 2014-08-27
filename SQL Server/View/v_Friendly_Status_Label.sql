USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Friendly_Status_Label]    Script Date: 08/26/2014 13:52:26 ******/
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

CREATE VIEW [dbo].[v_Friendly_Status_Label]
AS
    SELECT  ISTA.SIGNUP_DATE ,
            ISTA.SPE_NAME ,
            ISTA.CHANNEL_PARTNER ,
            SUM(ISTA.EXIT_SIGNUP_FAILED) AS EXIT_SIGNUP_FAILED ,
            SUM(ISTA.EXIT_SIGNUP_SUCCESS) AS EXIT_SIGNUP_SUCCESS ,
            SUM(ISTA.EXIT_SIGNUP_DUPLICATE) AS EXIT_SIGNUP_DUPLICATE ,
            SUM(ISTA.EXIT_SIGNUP_WITHDRAWN) AS EXIT_SIGNUP_WITHDRAWN ,
            SUM(ISTA.EXIT_OUTBOUND_QC_INITIATED) AS EXIT_OUTBOUND_QC_INITIATED ,
            SUM(ISTA.EXIT_OUTBOUND_QC_EXHAUSTED) AS EXIT_OUTBOUND_QC_EXHAUSTED ,
            SUM(ISTA.EXIT_QC_INIT_BUT_INCOMPLETE) AS EXIT_QC_INIT_BUT_INCOMPLETE ,
            SUM(ISTA.EXIT_QC_INVALID_REF_NUMBER) AS EXIT_QC_INVALID_REF_NUMBER ,
            SUM(ISTA.EXIT_QC_FAILED_IDENTIFY_CHECK) AS EXIT_QC_FAILED_IDENTIFY_CHECK ,
            SUM(ISTA.EXIT_QC_PRODUCT_UNAVAILABLE) AS EXIT_QC_PRODUCT_UNAVAILABLE ,
            SUM(ISTA.EXIT_QC_COMPLETE) AS EXIT_QC_COMPLETE ,
            SUM(ISTA.EXIT_DEP_UNSATISFIED) AS EXIT_DEP_UNSATISFIED ,
            SUM(ISTA.EXIT_DEP_AGREED_TO_PAY) AS EXIT_DEP_AGREED_TO_PAY ,
            SUM(ISTA.EXIT_DEP_PAID) AS EXIT_DEP_PAID ,
            SUM(ISTA.EXIT_DEP_BANK_IRRECOVERABLE) AS EXIT_DEP_BANK_IRRECOVERABLE ,
            SUM(ISTA.EXIT_DEP_WAIVED) AS EXIT_DEP_WAIVED ,
            SUM(ISTA.EXIT_DEP_WAIVED_ACH) AS EXIT_DEP_WAIVED_ACH ,
            SUM(ISTA.EXIT_DEP_WAIVED_IA) AS EXIT_DEP_WAIVED_IA ,
            SUM(ISTA.EXIT_DEP_WAIVED_FAMILY_VIOL) AS EXIT_DEP_WAIVED_FAMILY_VIOL ,
            SUM(ISTA.EXIT_DEP_WAIVED_LIDA) AS EXIT_DEP_WAIVED_LIDA ,
            SUM(ISTA.EXIT_DEP_WAIVED_GOOD_CREDIT) AS EXIT_DEP_WAIVED_GOOD_CREDIT ,
            SUM(ISTA.EXIT_DEP_WAIVED_ELDERLY) AS EXIT_DEP_WAIVED_ELDERLY ,
            SUM(ISTA.EXIT_ALREADY_ACTIVE) AS EXIT_ALREADY_ACTIVE ,
            SUM(ISTA.EXIT_SCHEDULE_DATE_UNAVAILABLE) AS EXIT_SCHEDULE_DATE_UNAVAILABLE ,
            SUM(ISTA.EXIT_24HOUR_HOLD_MANUAL) AS EXIT_24HOUR_HOLD_MANUAL ,
            SUM(ISTA.EXIT_24HOUR_HOLD_AUTOMATED) AS EXIT_24HOUR_HOLD_AUTOMATED ,
            SUM(ISTA.EXIT_ACCOUNT_CREATION) AS EXIT_ACCOUNT_CREATION ,
            SUM(ISTA.EXIT_ACCOUNT_CREATION_ERROR) AS EXIT_ACCOUNT_CREATION_ERROR ,
            SUM(ISTA.EXIT_ACCOUNT_CREATION_COMPLETE) AS EXIT_ACCOUNT_CREATION_COMPLETE ,
            SUM(ISTA.EXIT_ACCOUNT_ACTIVE) AS EXIT_ACCOUNT_ACTIVE ,
            SUM(ISTA.EXIT_ACCOUNT_INACTIVE) AS EXIT_ACCOUNT_INACTIVE ,
            SUM(ISTA.EXIT_ENROLL_CANCELLED_UTILITY) AS EXIT_ENROLL_CANCELLED_UTILITY ,
            SUM(ISTA.EXIT_ENROLL_CANCELLED_STREAM) AS EXIT_ENROLL_CANCELLED_STREAM ,
            SUM(ISTA.EXIT_ENROLL_ACCEPTED) AS EXIT_ENROLL_ACCEPTED ,
            SUM(ISTA.EXIT_ENROLL_REJECTED) AS EXIT_ENROLL_REJECTED ,
            SUM(ISTA.EXIT_ENROLL_PENDING) AS EXIT_ENROLL_PENDING ,
            SUM(ISTA.EXIT_ENROLL_COMPLETE) AS EXIT_ENROLL_COMPLETE ,
            SUM(ISTA.EXIT_DROP_ACCEPTED) AS EXIT_DROP_ACCEPTED ,
            SUM(ISTA.EXIT_DROP_PENDING) AS EXIT_DROP_PENDING ,
            SUM(ISTA.EXIT_DROP_REJECTED) AS EXIT_DROP_REJECTED ,
            SUM(ISTA.EXIT_DROP_CANCELLED) AS EXIT_DROP_CANCELLED ,
            SUM(ISTA.EXIT_DROP_COMPLETE) AS EXIT_DROP_COMPLETE
    FROM    ( SELECT 
	 --ec.CustomerAccountNumber, ec.CsrCustID, ec.EnrollCustID, 
	 --ec.enrollstatusid, es.statuscode, es.substatuscode, p.statusid,
                        CONVERT(VARCHAR(10) , ec.createdate , 101) AS 'SIGNUP_DATE' ,
                        m.state AS 'SPE_NAME' ,
                        CASE ss.salesourcedescription
                          WHEN 'ignite' THEN 'Ignite Websites'
                          WHEN 'call' THEN 'Telephonic'
                          WHEN 'paper' THEN 'LOA'
                          WHEN 'stream' THEN 'Streamenergy.net'
                          ELSE 'Other'
                        END AS 'CHANNEL_PARTNER' ,
                        CASE WHEN es.statuscode = '1000'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_SIGNUP_FAILED' ,
                        CASE WHEN es.statuscode = '1001'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_SIGNUP_SUCCESS' ,
                        0 AS 'EXIT_SIGNUP_DUPLICATE' ,
                        CASE WHEN es.statuscode = '1003'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_SIGNUP_WITHDRAWN' ,
                        CASE WHEN es.statuscode = '1005'
                                  AND es.SubStatusCode IS NULL
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_OUTBOUND_QC_INITIATED' ,
                        CASE WHEN es.statuscode = '1007'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_OUTBOUND_QC_EXHAUSTED' ,
                        CASE WHEN es.statuscode IN ( '1004' , '1005' , '1006' )
                                  AND es.SubStatusCode = '1'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_INIT_BUT_INCOMPLETE' ,
                        CASE WHEN es.statuscode IN ( '1004' , '1006' )
                                  AND es.SubStatusCode = '2'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_INVALID_REF_NUMBER' ,
                        CASE WHEN es.statuscode IN ( '1004' , '1006' )
                                  AND es.SubStatusCode = '3'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_FAILED_IDENTIFY_CHECK' ,
                        CASE WHEN es.statuscode IN ( '1004' , '1006' )
                                  AND es.SubStatusCode = '4'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_QC_PRODUCT_UNAVAILABLE' ,
                        0 AS 'EXIT_QC_COMPLETE' ,
                        0 AS 'EXIT_DEP_UNSATISFIED' ,
                        0 AS 'EXIT_DEP_AGREED_TO_PAY' ,
                        0 AS 'EXIT_DEP_PAID' ,
                        0 AS 'EXIT_DEP_BANK_IRRECOVERABLE' ,
                        0 AS 'EXIT_DEP_WAIVED' ,
                        0 AS 'EXIT_DEP_WAIVED_ACH' ,
                        0 AS 'EXIT_DEP_WAIVED_IA' ,
                        0 AS 'EXIT_DEP_WAIVED_FAMILY_VIOL' ,
                        0 AS 'EXIT_DEP_WAIVED_LIDA' ,
                        0 AS 'EXIT_DEP_WAIVED_GOOD_CREDIT' ,
                        0 AS 'EXIT_DEP_WAIVED_ELDERLY' ,
                        0 AS 'EXIT_ALREADY_ACTIVE' ,
                        0 AS 'EXIT_SCHEDULE_DATE_UNAVAILABLE' ,
                        CASE WHEN es.statuscode = '1009'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_24HOUR_HOLD_MANUAL' ,
                        CASE WHEN es.statuscode = '1008'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_24HOUR_HOLD_AUTOMATED' ,
                        CASE WHEN es.statuscode = '1010'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_ACCOUNT_CREATION' ,
                        CASE WHEN es.statuscode = '1011'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_ACCOUNT_CREATION_ERROR' ,
                        CASE WHEN es.statuscode = '1012'
                                  AND p.StatusID IS NULL THEN 1
                             ELSE 0
                        END AS 'EXIT_ACCOUNT_CREATION_COMPLETE' ,
                        CASE WHEN p.StatusID = '10' THEN 1
                             ELSE 0
                        END AS 'EXIT_ACCOUNT_ACTIVE' ,
                        CASE WHEN p.StatusID = '11'
                                  AND (/*t.StatusCode <> 'EB3' or*/ t.StatusCode IS NULL )
                             THEN 1
                             ELSE 0
                        END AS 'EXIT_ACCOUNT_INACTIVE' ,
                        CASE WHEN p.StatusID = 3 --in (5,6,11) 
				--and t.TransactionType = '814' 
					--and t.ActionCode = 'D'
						--and t.StatusCode = 'EB3' 
                                  AND ( t.Direction = '1'
                                        OR T.Direction IS NULL
                                      ) THEN 1  
			 --WHEN p.StatusID = '3'
				--THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_CANCELLED_UTILITY' ,
                        CASE WHEN p.StatusID = 3 --in (5,6,11) 
				--and t.TransactionType = '814' 
					--and t.ActionCode = 'D'
						--and t.StatusCode = 'EB3' 
                                  AND t.Direction = '0' THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_CANCELLED_STREAM' ,
                        CASE WHEN p.StatusID = '1' THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_ACCEPTED' ,
                        CASE WHEN p.StatusID IN ( '2' , '4' ) THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_REJECTED' ,
                        CASE WHEN p.StatusID = '0' THEN 1
                             ELSE 0
                        END AS 'EXIT_ENROLL_PENDING' ,
                        0 AS 'EXIT_ENROLL_COMPLETE' ,
                        CASE WHEN p.StatusID = '6'
                                  AND (/*t.StatusCode <> 'EB3' or*/ t.StatusCode IS NULL )
                             THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_ACCEPTED' ,
                        CASE WHEN p.StatusID = '5'
                                  AND (/*t.StatusCode <> 'EB3' or*/ t.StatusCode IS NULL )
                             THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_PENDING' ,
                        CASE WHEN p.StatusID IN ( '7' , '9' ) THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_REJECTED' ,
                        CASE WHEN p.StatusID = '8' THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_CANCELLED' ,
                        0 AS 'EXIT_DROP_COMPLETE'
              FROM      Stream.dbo.enrollcustomer AS ec
              LEFT JOIN Stream.dbo.EnrollCustomerPremise ecp ON ec.EnrollCustID = ecp.EnrollCustID
                                                              AND ecp.DeletedFlag = 0
	--JOIN enrollcustomerenrollstatushistory AS eh ON eh.enrollcustid=ec.enrollcustid
              LEFT JOIN Stream.dbo.enrollstatus AS es ON es.enrollstatusid = ec.EnrollStatusID
              LEFT JOIN Stream.dbo.salesource AS ss ON ss.salesourceid = ec.salessourceid
              LEFT JOIN Stream.dbo.Customer c ON ec.CsrCustID = c.CustID
              LEFT JOIN Stream.dbo.Premise p ON c.CustID = p.CustID
	/*left join Stream.dbo.CustomerTransactionRequest t on t.CustID = c.CustID 
												and p.StatusID in (6,11) 
													and t.TransactionType = '814' 
														and t.ActionCode = 'D'
															and t.ServiceActionCode in ('7','Q')*/
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
              WHERE     es.enrollstatusid NOT IN ( 3 )
            ) ISTA
    GROUP BY ISTA.SIGNUP_DATE ,
            ISTA.SPE_NAME ,
            ISTA.CHANNEL_PARTNER	







GO


