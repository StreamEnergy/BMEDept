USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_EAGLE_FreeGas]    Script Date: 08/26/2014 13:51:28 ******/
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

CREATE VIEW [dbo].[v_EAGLE_FreeGas]
AS
    SELECT  td.[IA Number] ADcode ,
            tc.[Customer Number] CDcode ,
            ROW_NUMBER() OVER ( PARTITION BY td.[IA Number] ORDER BY tc.[App Date] ) [CustNumber]
    FROM    EAGLE.dbo.tblAssociatesAndHomesites td WITH ( NOLOCK )
    INNER JOIN EAGLE.dbo.tblCustomers tc WITH ( NOLOCK ) ON tc.[Sponsor Number] = td.[IA Number]
                                                            AND LEFT(tc.[Customer Number] ,
                                                              1) = 'G'
                                                            AND tc.DStatusDesc IN (
                                                            'PreVerify' ,
                                                            'Pending' ,
                                                            'Active' )
    WHERE   tc.[App Date] > '2013-09-28 00:00:00.000'
            AND td.DStatusDesc = 'Active'
            AND td.Type = 'D'
            AND td.[IA Number] NOT IN ( 'A2' , 'A1' )
		

GO


