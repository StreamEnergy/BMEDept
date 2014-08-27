USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FEA_AssociateNoDesignatedAccountListing]    Script Date: 08/26/2014 13:38:30 ******/
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


CREATE VIEW [dbo].[v_EAGLE_FEA_AssociateNoDesignatedAccountListing]
AS
    WITH    FreeEnergyEligibleIAs
              AS ( SELECT   ia.AssociateNumber ,
                            CASE WHEN ISNULL(conf.Conference , '') = ''
                                 THEN '15'
                                 ELSE '12'
                            END [TotalRequired] ,
                            SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'C'
                                          AND c.[Active Date] >= '2013-09-28'
                                     THEN 1
                                     ELSE 0
                                END) AS [TotalElecCust] ,
                            SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'C'
                                          AND c.[Active Date] >= '2014-02-22'
                                     THEN 1
                                     ELSE 0
                                END) AS [HWY2FDMElecCust] ,
                            SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'G'
                                          AND c.[Active Date] >= '2013-09-28'
                                     THEN 1
                                     ELSE 0
                                END) AS [TotalGasCust] ,
                            SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'G'
                                          AND c.[Active Date] >= '2014-02-22'
                                     THEN 1
                                     ELSE 0
                                END) AS [HWY2FDMGasCust]
                   FROM     EAGLE.dbo.tblIgniteAssociates ia
                   INNER JOIN EAGLE.dbo.tblCustomers c ON ia.AssociateNumber = c.[Sponsor Number]
                   LEFT OUTER JOIN EAGLE.dbo.RPParticipant rpp ON ia.AssociateNumber = rpp.AccountNumber
                   LEFT OUTER JOIN EAGLE.dbo.RPReferredAccount rpr ON c.[Customer Number] = rpr.ReferredAccountNumber
                   LEFT OUTER JOIN EAGLE.dbo.tblConferences conf ON ia.AssociateNumber = conf.[IA Number]
                                                              AND conf.Conference = 'Ignition 2014'
                   WHERE    rpp.AccountNumber IS NULL
                            AND rpr.ReferredAccountNumber IS NULL
                            AND c.DStatusDesc = 'Active'
                            AND c.[Active Date] >= '2013-09-28'
                            AND LEFT(c.[Customer Number] , 1) IN ( 'G' , 'C' )
                   GROUP BY ia.AssociateNumber ,
                            conf.Conference
                   HAVING   SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'G'
                                          AND c.[Active Date] >= '2014-02-22'
                                     THEN 1
                                     ELSE 0
                                END) > 4
                            OR SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'C'
                                             AND c.[Active Date] >= '2014-02-22'
                                        THEN 1
                                        ELSE 0
                                   END) > 4
                            OR SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'G'
                                             AND c.[Active Date] >= '2013-09-28'
                                             AND conf.Conference = 'Ignition 14'
                                        THEN 1
                                        ELSE 0
                                   END) > 11
                            OR SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'C'
                                             AND c.[Active Date] >= '2013-09-28'
                                             AND conf.Conference = 'Ignition 14'
                                        THEN 1
                                        ELSE 0
                                   END) > 11
                            OR SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'G'
                                             AND c.[Active Date] >= '2013-09-28'
                                             AND conf.Conference IS NULL
                                        THEN 1
                                        ELSE 0
                                   END) > 14
                            OR SUM(CASE WHEN LEFT(c.[Customer Number] , 1) = 'C'
                                             AND c.[Active Date] >= '2013-09-28'
                                             AND conf.Conference IS NULL
                                        THEN 1
                                        ELSE 0
                                   END) > 14
                 )
    SELECT  fe.AssociateNumber ,
            CASE WHEN fe.TotalElecCust < 15
                      AND fe.TotalRequired = 15
                      AND HWY2FDMElecCust BETWEEN 5 AND 9 THEN '25'
                 WHEN fe.TotalElecCust < 12
                      AND fe.TotalRequired = 12
                      AND HWY2FDMElecCust BETWEEN 5 AND 9 THEN '25'
                 WHEN fe.TotalElecCust < 15
                      AND fe.TotalRequired = 15
                      AND HWY2FDMElecCust BETWEEN 10 AND 14 THEN '50'
                 WHEN fe.TotalElecCust < 12
                      AND fe.TotalRequired = 12
                      AND HWY2FDMElecCust BETWEEN 10 AND 11 THEN '50'
                 WHEN fe.TotalElecCust >= 15
                      AND fe.TotalRequired = 15 THEN '100'
                 WHEN fe.TotalElecCust >= 12
                      AND fe.TotalRequired = 12 THEN '100'
                 ELSE '0'
            END AS 'ElectricCreditPercentage' ,
            fe.HWY2FDMElecCust ,
            fe.TotalElecCust ,
            CASE WHEN fe.TotalGasCust < 15
                      AND fe.TotalRequired = 15
                      AND HWY2FDMGasCust BETWEEN 5 AND 9 THEN '25'
                 WHEN fe.TotalGasCust < 12
                      AND fe.TotalRequired = 12
                      AND HWY2FDMGasCust BETWEEN 5 AND 9 THEN '25'
                 WHEN fe.TotalGasCust < 15
                      AND fe.TotalRequired = 15
                      AND HWY2FDMGasCust BETWEEN 10 AND 14 THEN '50'
                 WHEN fe.TotalGasCust < 12
                      AND fe.TotalRequired = 12
                      AND HWY2FDMGasCust BETWEEN 10 AND 11 THEN '50'
                 WHEN fe.TotalGasCust >= 15
                      AND fe.TotalRequired = 15 THEN '100'
                 WHEN fe.TotalGasCust >= 12
                      AND fe.TotalRequired = 12 THEN '100'
                 ELSE '0'
            END AS 'GasCreditPercentage' ,
            fe.HWY2FDMGasCust ,
            fe.TotalGasCust
    FROM    FreeEnergyEligibleIAs fe


GO


