USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_CP_Onflow_vs_Market]    Script Date: 08/26/2014 13:35:11 ******/
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


CREATE VIEW [dbo].[v_CP_Onflow_vs_Market]
AS
    SELECT  CASE WHEN Subquery.PremNo IS NOT NULL THEN Subquery.PremNo
                 ELSE Subquery_1.Esiid
            END AS Link ,
            Subquery.PremNo ,
            Subquery.LDCNo ,
            'TX' AS State ,
            Subquery_1.Esiid AS MktRef ,
            'PremNo' AS MktRefField ,
            ( SELECT    CAST(MAX(starttimedate) AS DATE)
              FROM      [StreamInternal].[dbo].[CP_SCR727_TX]
            ) AS OnFlowSyncDate ,
            CASE WHEN Subquery.PremNo IS NOT NULL THEN 'Y'
                 ELSE 'N'
            END AS OnFlowCP
    FROM    ( SELECT DISTINCT
                        cp.PremNo ,
                        cp.LDCNo
              FROM      StreamInternal.dbo.CustomerProfile cp
              WHERE     ( SELECT    CAST(MAX(starttimedate) AS DATE)
                          FROM      [StreamInternal].[dbo].[CP_SCR727_TX]
                        ) BETWEEN cp.BeginServiceDate
                          AND     ISNULL(cp.EndServiceDate , '12/31/2999')
                        AND cp.BeginServiceDate < ISNULL(cp.EndServiceDate ,
                                                         '12/31/2999')
                        AND cp.DataSource = 'CIS1'
            ) Subquery
    FULL OUTER JOIN ( SELECT    s.Esiid
                      FROM      StreamInternal.dbo.CP_SCR727_TX s
                    ) Subquery_1 ON ( Subquery.PremNo = Subquery_1.Esiid )
    WHERE   Subquery.PremNo IS NULL
            OR Subquery_1.Esiid IS NULL
    UNION ALL

------------------
--GA FDCG
------------------
    SELECT  CASE WHEN Subquery.LDCNo IS NOT NULL THEN Subquery.LDCNo
                 ELSE Subquery_1.LDC_ACCOUNT_NUMBER
            END AS Link ,
            Subquery.PremNo ,
            Subquery.LDCNo ,
            'GA' AS State ,
            Subquery_1.LDC_ACCOUNT_NUMBER AS MktRef ,
            'LDCNo' AS MktRefField ,
            ( SELECT    CAST(MAX(v.LASTREAD) AS DATE)
              FROM      StreamInternal.dbo.CustomerProfile_GA_TransData_v v
            ) AS OnFlowSyncDate ,
            CASE WHEN Subquery.LDCNo IS NOT NULL THEN 'Y'
                 ELSE 'N'
            END AS OnFlowCP
    FROM    ( SELECT DISTINCT
                        cp.PremNo ,
                        cp.LDCNo
              FROM      StreamInternal.dbo.CustomerProfile cp
              WHERE     ( SELECT    CAST(MAX(v.LASTREAD) AS DATE)
                          FROM      StreamInternal.dbo.CustomerProfile_GA_TransData_v v
                        ) BETWEEN cp.BeginServiceDate
                          AND     ISNULL(cp.EndServiceDate , '12/31/2999')
                        AND cp.BeginServiceDate < ISNULL(cp.EndServiceDate ,
                                                         '12/31/2999')
                        AND cp.DataSource = 'CIS2'
            ) Subquery
    FULL OUTER JOIN ( SELECT    g.LDC_ACCOUNT_NUMBER
                      FROM      StreamInternal.dbo.CustomerProfile_GA_TransData_v g
                      WHERE     ( g.[LASTREAD] = ( SELECT   MAX(v.LASTREAD)
                                                   FROM     StreamInternal.dbo.CustomerProfile_GA_TransData_v v
                                                 ) )
                    ) Subquery_1 ON ( Subquery.LDCNo = Subquery_1.LDC_ACCOUNT_NUMBER )
    WHERE   Subquery.LDCNo IS NULL
            OR Subquery_1.LDC_ACCOUNT_NUMBER IS NULL
 






GO


