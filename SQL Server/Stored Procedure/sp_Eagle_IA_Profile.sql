USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Eagle_IA_Profile]    Script Date: 08/25/2014 12:15:42 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
		
08/15/2014 				Jide Akintoye						Format Stored procedure




**********************************************************************************************/



CREATE PROCEDURE [dbo].[sp_Eagle_IA_Profile]
AS
    BEGIN

        DROP TABLE [dbo].[IAProfile]

        CREATE TABLE [dbo].[IAProfile]
            ( [IAProfileID] [INT] IDENTITY(10000 , 1) NOT FOR REPLICATION
                                  NOT NULL ,
              [ANum] [VARCHAR](100) NULL ,
              [IA_First_Name] [VARCHAR](100) NULL ,
              [IA_Last_Name] [VARCHAR](100) NULL ,
              [Home_Phone] [VARCHAR](100) NULL ,
              [Work_Phone] [VARCHAR](100) NULL ,
              [Mobile_Phone] [VARCHAR](100) NULL ,
              [SSN] [VARCHAR](4) NULL ,
              [Email] [VARCHAR](100) NULL ,
              [Billing_Address] [VARCHAR](100) NULL ,
              [Billing_City] [VARCHAR](100) NULL ,
              [Billing_State] [VARCHAR](100) NULL ,
              [Billing_Zip] [VARCHAR](100) NULL ,
              [WebAlias] [VARCHAR](100) NULL ,
              [Shipping_Address] [VARCHAR](100) NULL ,
              [Shipping_City] [VARCHAR](100) NULL ,
              [Shipping_State] [VARCHAR](100) NULL ,
              [Shipping_Zip] [VARCHAR](100) NULL ,
              [Status] [VARCHAR](100) NULL ,
              [Rank] [VARCHAR](100) NULL ,
              [App_Date] [DATETIME] NULL ,
              [Rec] [VARCHAR](100) NULL ,
              [DOB] [DATETIME] NULL ,
              [eSuite] [VARCHAR](100) NULL ,
              [DataSource] [VARCHAR](100) NULL ,
              [RecordDate] [DATETIME] NULL ,
              [RecordCreatedBy] [VARCHAR](100) NULL ,
              [RecordLastUpdatedBy] [VARCHAR](100) NULL ,
              [RecordLastUpdatedDate] [DATETIME] NULL ,
              CONSTRAINT [IAProfileID] PRIMARY KEY CLUSTERED
                ( [IAProfileID] ASC )
                WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF ,
                       IGNORE_DUP_KEY = OFF , ALLOW_ROW_LOCKS = ON ,
                       ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
            )
        ON  [PRIMARY]

--DELETE FROM  [StreamInternal].[dbo].[IAProfile];

        INSERT  INTO [StreamInternal].[dbo].IAProfile
                ( ANum ,
                  IA_First_Name ,
                  IA_Last_Name ,
                  Home_Phone ,
                  Work_Phone ,
                  Mobile_Phone ,
                  SSN ,
                  Email ,
                  Billing_Address ,
                  Billing_City ,
                  Billing_State ,
                  Billing_Zip ,
                  WebAlias ,
                  Shipping_Address ,
                  Shipping_City ,
                  Shipping_State ,
                  Shipping_Zip ,
                  Status ,
                  Rank ,
                  App_Date ,
                  Rec ,
                  DOB ,
                  eSuite ,
                  DataSource ,
                  RecordCreatedBy ,
                  RecordDate ,
                  RecordLastUpdatedBy ,
                  RecordLastUpdatedDate
                )
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
                        a.DStatusDesc AS STATUS ,
                        a.[IA Level] AS RANK ,
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
			DISTINCT                h.[IA Number] ,
                                    CASE WHEN o.[Order Total] = '0.00'
                                         THEN 'Free'
                                         WHEN o.[Order Total] = '0'
                                         THEN 'Free'
                                         WHEN o.[Order Total] = '19.95'
                                         THEN 'Homesite'
                                         WHEN o.[Order Total] = '24.95'
                                         THEN 'ESuite'
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
				DISTINCT            ha.[IA Number] ,
                                    CASE WHEN tp.Price = '0.00' THEN 'Free'
                                         WHEN tp.Price = '0' THEN 'Free'
                                         WHEN tp.Price = '19.95'
                                         THEN 'Homesite'
                                         WHEN tp.Price = '24.95' THEN 'ESuite'
                                         ELSE 'Other'
                                    END AS flag
                            FROM    Eagle.dbo.tblHomesitesAll ha
                            INNER JOIN Eagle.dbo.tblProducts tp ON ha.PCode = tp.Pcode
                            WHERE   Status = 'Active'
                          ) h ON h.[IA Number] = a.[IA Number]		
			
			--Old
			--		  (select 
			--distinct
			--h.[IA Number],
			--case 
			--	when o.[Order Total] = '0.00' then 'Free'
			--	when o.[Order Total] = '0' then 'Free'
			--	when o.[Order Total] = '19.95' then 'Homesite'
			--	when o.[Order Total] = '24.95' then 'ESuite'
			--	else 'Other'
			--end as flag
			--from eagle.dbo.tblOrderHead o 
			--left join Eagle.dbo.tblOrderDetail d on d.[Order Number] = o.[Order Number]
			--left join Eagle.dbo.tblHomesitesAll h on h.[Homesite Number] = o.[IA Number]
			--left join Eagle.dbo.tblProducts p on d.Item = p.Pcode
			--where 
			--o.[Order Date] between GETDATE()-45 and GETDATE()
			--and
			--p.[Product Description] like '%Homesite%'
			--) h on h.[IA Number] = a.[IA Number]	
                LEFT JOIN ( SELECT  r.[Sponsor Number] ,
                                    COUNT(r.ID) AS RecCount
                            FROM    Eagle.dbo.tblRecs R
                            GROUP BY r.[Sponsor Number]
                          ) AS Rec ON Rec.[Sponsor Number] = a.[IA Number]
    END










GO


