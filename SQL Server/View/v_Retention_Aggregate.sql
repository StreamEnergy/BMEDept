USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_Retention_Aggregate]    Script Date: 08/26/2014 15:13:40 ******/
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



CREATE VIEW [dbo].[v_Retention_Aggregate]
AS
    SELECT  drops.SPE_NAME ,
            drops.DROP_TYPE ,
            drops.SIGNUP_DATE ,
            drops.GAINING_REP ,
            SUM(drops.DROP_ATTEMPTS) AS DROP_ATTEMPTS ,
            SUM(drops.EXIT_DROP_PENDING) AS EXIT_DROP_PENDING ,
            SUM(drops.EXIT_DROP_REJECTED) AS EXIT_DROP_REJECTED ,
            SUM(drops.EXIT_DROP_CANCELLED) AS EXIT_DROP_CANCELLED ,
            SUM(drops.EXIT_DROP_COMPLETE) AS EXIT_DROP_COMPLETE
    FROM    ( SELECT    ps.Status ,
                        ps.PremiseStatusID ,
                        m.State AS 'SPE_NAME' ,
                        CASE WHEN t.StatusCode = '007'
                             THEN '007 - Service terminated or customer dropped because of nonpayment'
                             WHEN t.StatusCode = '020'
                             THEN '020 - Customer moved or account closed'
                             WHEN t.StatusCode = 'CHA'
                             THEN 'CHA - Customer changed to another Service Provider'
                             WHEN t.StatusCode = 'A13' THEN 'A13 - Other'
                             WHEN t.StatusCode = 'B38'
                             THEN 'B38 - Dropped by Customer Request'
                             WHEN t.StatusCode = 'CCE'
                             THEN 'CCE - Contract Expired'
                             WHEN t.StatusCode = 'C02'
                             THEN 'C02 - Customer is on Credit Hold'
                             WHEN t.StatusCode = 'C03'
                             THEN 'C03 - Customer Enrolled in USF'
                             WHEN t.StatusCode = 'EB3' THEN 'EB3 - Withdrawn'
                             WHEN t.StatusCode = 'B42'
                             THEN 'B42 - Alleged Slam'
                             WHEN t.StatusCode = 'B39'
                             THEN 'B39 - Already Dropped'
                        END AS DROP_TYPE ,
                        CONVERT(VARCHAR(10) , t.TransactionDate , 101) AS 'SIGNUP_DATE' ,
                        1 AS DROP_ATTEMPTS ,
            --t.requestid, p.StatusID, ps.Status,
                        CASE WHEN p.StatusID = 5 THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_PENDING' ,
                        CASE WHEN p.StatusID IN ( 6 , 11 ) THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_COMPLETE' ,
                        CASE WHEN p.StatusID = 7 THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_REJECTED' ,
                        CASE WHEN p.StatusID IN ( 0 , 1 , 2 , 3 , 4 , 8 , 9 ,
                                                  10 ) THEN 1
                             ELSE 0
                        END AS 'EXIT_DROP_CANCELLED' ,
                        NULL AS GAINING_REP
              FROM      Stream.dbo.customertransactionrequest t
              LEFT JOIN Stream.dbo.Premise p ON t.CustID = p.CustID
              LEFT JOIN Stream.dbo.PremiseStatus ps ON p.StatusID = ps.PremiseStatusID
              LEFT JOIN Stream.dbo.LDCLookup l ON p.LDCID = l.LDCID
              LEFT JOIN StreamInternal.dbo.Market m ON l.MarketID = m.MarketID
              WHERE     t.TransactionType = '814'
                        AND t.ActionCode = 'D'
                        AND t.ServiceActionCode IN ( 'Q' , '7' )
            ) drops
    GROUP BY drops.SPE_NAME ,
            drops.DROP_TYPE ,
            drops.SIGNUP_DATE ,
            drops.GAINING_REP




GO


