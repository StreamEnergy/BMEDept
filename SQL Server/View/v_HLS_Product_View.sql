USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_HLS_Product_View]    Script Date: 08/26/2014 14:19:43 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
07/25/2014				Jide Akintoye						List of Products contained in the  HLS Customer Data.					
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/


CREATE VIEW [dbo].[v_HLS_Product_View]
AS
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS ProductID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE WHEN ProductCode IN ( 'seidcrit01' , 'seidcrit02' ,
                                       'seidcr01' , 'seidit01' , 'seidcr02' ,
                                       'seidit02' , 'seid01' , 'seid02' )
                 THEN 'IdentityProtection'
                 ELSE NULL
            END AS 'Product'
    FROM    dbo.HLS_Customers_Data H
    UNION ALL
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS ProductID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE WHEN ProductCode IN ( 'seidcrit01' , 'seidcrit02' ,
                                       'seidcr01' , 'seidcr02' , 'secrit02' ,
                                       'secrit01' , 'secr01' , 'secr02' )
                 THEN 'CreditMonitoring'
                 ELSE NULL
            END AS 'Product'
    FROM    dbo.HLS_Customers_Data H
    UNION ALL
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS ProductID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE WHEN ProductCode IN ( 'seidcrit01' , 'seidcrit02' ,
                                       'seidit02' , 'secrit02' , 'secrit01' ,
                                       'seidit01' , 'seit01' , 'seit02' )
                 THEN 'TechSupport'
                 ELSE NULL
            END AS 'Product'
    FROM    dbo.HLS_Customers_Data H
    UNION
    SELECT  ROW_NUMBER() OVER ( ORDER BY ProductCode ) AS ProductID ,
            VendorCustomerNumber ,
            ProductCode ,
            CASE WHEN ProductCode IN ( 'seatechftby' , 'seatechby ' ,
                                       'seaidftby' , 'seaidby' , 'seacrftby' ,
                                       'seacrby' ) THEN 'Family_Addon'
                 ELSE NULL
            END AS 'Product'
    FROM    dbo.HLS_Customers_Data H







GO


