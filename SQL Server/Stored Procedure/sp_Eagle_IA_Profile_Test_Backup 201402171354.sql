USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Eagle_IA_Profile_Test_Backup 201402171354]    Script Date: 08/25/2014 12:16:31 ******/
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



CREATE PROCEDURE [dbo].[sp_Eagle_IA_Profile_Test_Backup 201402171354]
AS
    BEGIN
        DROP TABLE IAProfile_Test
        CREATE TABLE dbo.IAProfile_Test
            ( [IAProfileID] [INT] IDENTITY(10000 , 1) NOT FOR REPLICATION
                                  NOT NULL ,
              ANum VARCHAR(100) ,
              IA_First_Name VARCHAR(100) ,
              IA_Last_Name VARCHAR(100) ,
              Home_Phone VARCHAR(100) ,
              Work_Phone VARCHAR(100) ,
              Mobile_Phone VARCHAR(100) ,
              SSN VARCHAR(4) ,
              Email VARCHAR(100) ,
              Billing_Address VARCHAR(100) ,
              Billing_City VARCHAR(100) ,
              Billing_State VARCHAR(100) ,
              Billing_Zip VARCHAR(100) ,
              WebAlias VARCHAR(100) ,
              Shipping_Address VARCHAR(100) ,
              Shipping_City VARCHAR(100) ,
              Shipping_State VARCHAR(100) ,
              Shipping_Zip VARCHAR(100) ,
              Status VARCHAR(100) ,
              Rank VARCHAR(100) ,
              App_Date DATETIME ,
              Rec VARCHAR(100) ,
              DOB DATETIME ,
              eSuite VARCHAR(100) ,
              DataSource VARCHAR(100) ,
              RecordDate DATETIME ,
              RecordCreatedBy VARCHAR(100) ,
              RecordLastUpdatedBy VARCHAR(100) ,
              RecordLastUpdatedDate DATETIME ,
              CONSTRAINT [IAProfileID] PRIMARY KEY CLUSTERED
                ( [IAProfileID] ASC )
                WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF ,
                       IGNORE_DUP_KEY = OFF , ALLOW_ROW_LOCKS = ON ,
                       ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
            )
        ON  [PRIMARY]

        INSERT  INTO [StreamInternal].[dbo].IAProfile_Test
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
                        RIGHT(a.SSN , 4) AS SSN ,
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
                        h.PCode AS eSuite ,
                        'Eagle' AS DataSource ,
                        USER AS RecordCreatedBy ,
                        GETDATE() AS RecordDate ,
                        USER AS RecordLastUpdatedBy ,
                        GETDATE() AS RecordLastUpdatedDate
                FROM    Eagle.dbo.tblAssociatesAndHomesites a
                LEFT JOIN Eagle.dbo.tblHomesitesAll h ON a.[IA Number] = h.[IA Number]
                LEFT JOIN ( SELECT  r.[Sponsor Number] ,
                                    COUNT(r.ID) AS RecCount
                            FROM    Eagle.dbo.tblRecs R
                            GROUP BY r.[Sponsor Number]
                          ) AS Rec ON Rec.[Sponsor Number] = a.[IA Number]
	
	
	
    END


GO


