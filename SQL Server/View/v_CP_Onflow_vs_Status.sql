USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_CP_Onflow_vs_Status]    Script Date: 08/26/2014 13:35:23 ******/
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


CREATE VIEW [dbo].[v_CP_Onflow_vs_Status]
AS
    SELECT  CASE WHEN Subquery.LDCNo IS NOT NULL THEN Subquery.LDCNo
                 ELSE Subquery_1.LDCNo
            END AS LDCNo ,
            CASE WHEN Subquery.PremStatus IS NOT NULL THEN Subquery.PremStatus
                 ELSE Subquery_1.PremStatus
            END AS PremStatus
 --,Subquery_1.LDCNo AS Status_LDC_No
 --,Subquery_1.PremStatus AS Status_LDC_Status
            ,
            CASE WHEN Subquery.LDCNo IS NULL THEN 'No'
                 WHEN Subquery_1.LDCNo IS NULL THEN 'Yes'
                 ELSE 'Unknown'
            END AS 'On-Flow'
    FROM    ( SELECT    CustomerProfile.LDCNo ,
                        CustomerProfile.PremStatus
              FROM      StreamInternal.dbo.CustomerProfile CustomerProfile
              WHERE     ( CAST(GETDATE() AS DATE) BETWEEN CustomerProfile.BeginServiceDate
                                                  AND     ISNULL(CustomerProfile.EndServiceDate ,
                                                              '12/31/2999')
                          AND CustomerProfile.BeginServiceDate < ISNULL(CustomerProfile.EndServiceDate ,
                                                              '12/31/2999')
                        )
              GROUP BY  CustomerProfile.LDCNo ,
                        CustomerProfile.PremStatus
            ) Subquery
    FULL OUTER JOIN ( SELECT    CustomerProfile.LDCNo ,
                                CustomerProfile.PremStatus
                      FROM      StreamInternal.dbo.CustomerProfile CustomerProfile
                      WHERE     ( ( [CustomerProfile].[PremStatusID] IN ( 5 ,
                                                              6 , 7 , 8 , 9 ,
                                                              10 )
                                    AND CustomerProfile.DataSource = 'Ista'
                                  )
                                  OR ( CustomerProfile.PremStatusID LIKE '04%'
                                       AND CustomerProfile.DataSource = 'CIS2'
                                     )
                                  OR ( CustomerProfile.PremStatusID IN ( '04' ,
                                                              '06' )
                                       AND CustomerProfile.DataSource = 'CIS1'
                                     )
                                )
                      GROUP BY  CustomerProfile.LDCNo ,
                                CustomerProfile.PremStatus
                    ) Subquery_1 ON ( Subquery.LDCNo = Subquery_1.LDCNo )
    WHERE   Subquery.LDCNo IS NULL
            OR Subquery_1.LDCNo IS NULL  






GO


