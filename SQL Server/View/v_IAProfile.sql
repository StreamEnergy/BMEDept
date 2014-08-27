USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_IAProfile]    Script Date: 08/26/2014 14:19:54 ******/
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

CREATE VIEW [dbo].[v_IAProfile]
AS
    SELECT
--rank() over (a.[IA Number]) as IAProfileID,
            a.[IA Number] AS ANum ,
            a.Name_First AS IA_First_Name ,
            a.Name_Last AS IA_Last_Name ,
            a.[Home Phone] AS Home_Phone ,
            a.[Work Phone] AS Work_Phone ,
            a.[Cell Phone] AS Mobile_Phone ,
--right(a.SSN,4) as SSN,
            CASE WHEN LEN(a.ssn) = 4 THEN RIGHT(a.SSN , 4)
                 ELSE RIGHT(a.[IA Tax ID] , 4)
            END AS SSN ,
            a.[Primary Email] AS Email ,
            a.[Billing Address1] AS Billing_Address ,
            a.[Billing City] AS Billing_City ,
            a.[Billing State] AS Billing_State ,
            a.[Billing Zip] AS Billing_Zip ,
            a.webalias AS WebAlias ,
            a.[Shipping Address1] AS Shipping_Address ,
            a.[Shipping City] AS Shipping_City ,
            a.[Shipping State] AS Shipping_State ,
            a.[Shipping Zip] AS Shipping_Zip ,
            a.DStatusDesc AS Status ,
            a.[IA Level] AS Rank ,
            a.[IA App Date] AS App_Date ,
            Rec.RecCount AS Rec ,
            a.[Date of Birth] AS DOB ,
            CASE WHEN h.flag IS NULL THEN 'No Homesite'
                 ELSE h.flag
            END AS eSuite ,
            'Eagle' AS DataSource ,
            'sp_Eagle_IA_Profile' AS RecordCreatedBy ,
            GETDATE() AS RecordDate ,
            'sp_Eagle_IA_Profile' AS RecordLastUpdatedBy ,
            GETDATE() AS RecordLastUpdatedDate
    FROM    Eagle.dbo.tblAssociatesAndHomesites a
    LEFT JOIN ( SELECT 
			DISTINCT    h.[IA Number] ,
                        CASE WHEN o.[Order Total] = '0.00' THEN 'Free'
                             WHEN o.[Order Total] = '0' THEN 'Free'
                             WHEN o.[Order Total] = '19.95' THEN 'Homesite'
                             WHEN o.[Order Total] = '24.95' THEN 'ESuite'
                             ELSE 'Other'
                        END AS flag
                FROM    Eagle.dbo.tblHomesitesAll h
                LEFT JOIN Eagle.dbo.tblProducts p ON h.PCode = p.Pcode
                LEFT JOIN eagle.dbo.tblOrderHead o ON o.[IA Number] = h.[Homesite Number]
                LEFT JOIN Eagle.dbo.tblOrderDetail d ON d.[Order Number] = o.[Order Number]
                WHERE   o.[Order Date] BETWEEN GETDATE() - 45 AND GETDATE()
                        AND o.[Order Total] IN ( '0.00' , '0' )
                UNION
                SELECT
				DISTINCT
                        ha.[IA Number] ,
                        CASE WHEN tp.Price = '0.00' THEN 'Free'
                             WHEN tp.Price = '0' THEN 'Free'
                             WHEN tp.Price = '19.95' THEN 'Homesite'
                             WHEN tp.Price = '24.95' THEN 'ESuite'
                             ELSE 'Other'
                        END AS flag
                FROM    Eagle.dbo.tblHomesitesAll ha
                INNER JOIN Eagle.dbo.tblProducts tp ON ha.PCode = tp.Pcode
                WHERE   Status = 'Active'
              ) h ON h.[IA Number] = a.[IA Number]
    LEFT JOIN ( SELECT  r.[Sponsor Number] ,
                        COUNT(r.ID) AS RecCount
                FROM    Eagle.dbo.tblRecs R
                GROUP BY r.[Sponsor Number]
              ) AS Rec ON Rec.[Sponsor Number] = a.[IA Number]







GO


