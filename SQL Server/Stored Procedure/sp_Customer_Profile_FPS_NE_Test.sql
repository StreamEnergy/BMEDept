USE [StreamInternal]
GO

/****** Object:  StoredProcedure [dbo].[sp_Customer_Profile_FPS_NE_Test]    Script Date: 08/25/2014 09:51:52 ******/
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





CREATE PROCEDURE [dbo].[sp_Customer_Profile_FPS_NE_Test]
AS
    BEGIN

        IF EXISTS ( SELECT  *
                    FROM    sys.objects
                    WHERE   object_id = OBJECT_ID(N'[dbo].[CP_FPS_NE_Test]')
                            AND type IN ( N'U' ) )
            DROP TABLE [dbo].[CP_FPS_NE_Test]


        CREATE TABLE [dbo].[CP_FPS_NE_Test]
            ( [FPSProfileID] [INT] IDENTITY(1000 , 1) NOT FOR REPLICATION
                                   NOT NULL ,
              [LDCID] [VARCHAR](30) NULL ,
              [LDCCode] [VARCHAR](30) NULL ,
              [WeatherZone] [VARCHAR](30) NULL ,
              [LoadZone] [VARCHAR](30) NULL ,
              [StateAbbr] [VARCHAR](25) NULL ,
              [CustID] [VARCHAR](100) NULL ,
              [CustNo] [VARCHAR](100) NULL ,
              [PremID] [VARCHAR](100) NULL ,
              [PremNo] [VARCHAR](100) NULL ,
              [RateDetID] [VARCHAR](100) NULL ,
              [MeterNo] [VARCHAR](100) NULL ,
              [MeterID] [VARCHAR](100) NULL ,
              [RateClass] [VARCHAR](30) NULL ,
              [LoadProfile] [VARCHAR](30) NULL ,
              [Strata] [VARCHAR](30) NULL ,
              [BeginServiceDate] [DATETIME] NULL ,
              [EndServiceDate] [DATETIME] NULL ,
              [EffectiveDate] [DATETIME] NULL ,
              [ExpirationDate] [DATETIME] NULL ,
              [PlanType] [VARCHAR](10) NULL ,
              [Active] [VARCHAR](10) NULL ,
              [ContractStatus] [VARCHAR](50) NULL ,
              [PremiseStatusID] [VARCHAR](10) NULL ,
              [PremiseStatus] [VARCHAR](50) NULL ,
              [CustType] [VARCHAR](10) NULL ,
              [ServiceCycle] [VARCHAR](10) NULL ,
              [DataSource] [VARCHAR](100) NULL ,
              [RecordDate] [DATETIME] NULL ,
              [RecordCreatedBy] [VARCHAR](100) NULL ,
              [RecordLastUpdatedBy] [VARCHAR](100) NULL ,
              [RecordLastUpdatedDate] [DATETIME] NULL ,
              CONSTRAINT [FPSProfileID] PRIMARY KEY CLUSTERED
                ( [FPSProfileID] ASC )
                WITH ( PAD_INDEX = OFF , STATISTICS_NORECOMPUTE = OFF ,
                       IGNORE_DUP_KEY = OFF , ALLOW_ROW_LOCKS = ON ,
                       ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
            )
        ON  [PRIMARY]

--DELETE FROM  [StreamInternal].[dbo].[CP_FPS_NE_Test];

        INSERT  INTO [StreamInternal].[dbo].CP_FPS_NE_Test
                ( LDCID ,
                  LDCCode ,
                  WeatherZone ,
                  LoadZone ,
                  StateAbbr ,
                  CustID ,
                  CustNo ,
                  PremID ,
                  PremNo ,
                  RateDetID ,
                  MeterNo ,
                  MeterID ,
                  RateClass ,
                  LoadProfile ,
                  Strata ,
                  BeginServiceDate ,
                  EndServiceDate ,
                  EffectiveDate ,
                  ExpirationDate ,
                  PlanType ,
                  Active ,
                  ContractStatus ,
                  PremiseStatusID ,
                  PremiseStatus ,
                  CustType ,
                  ServiceCycle ,
                  [DataSource] ,
                  [RecordCreatedBy] ,
                  [RecordDate] ,
                  [RecordLastUpdatedBy] ,
                  [RecordLastUpdatedDate] 			
                )
                SELECT DISTINCT
                        f.LDCID ,
                        f.LDCCode ,
                        f.WeatherZone ,
                        f.LoadZone ,
                        f.StateAbbr ,
                        f.CustID ,
                        f.CustNo ,
                        f.PremID ,
                        f.PremNo ,
                        f.RateDetID ,
                        f.MeterNo ,
                        f.MeterID ,
                        f.RateClass ,
                        f.LoadProfile ,
                        f.Strata ,
                        f.BeginServiceDate ,
                        f.EndServiceDate ,
                        f.EffectiveDate ,
                        f.ExpirationDate ,
                        f.PlanType ,
                        f.Active ,
                        f.ContractStatus ,
                        f.PremiseStatusID ,
                        f.PremiseStatus ,
                        f.CustType ,
                        f.ServiceCycle ,
                        'ISTA' AS DataSource ,
                        'sp_Customer_Profile_FPS_NE' AS RecordCreatedBy ,
                        GETDATE() AS RecordDate ,
                        'sp_Customer_Profile_FPS_NE' AS RecordLastUpdatedBy ,
                        GETDATE() AS RecordLastUpdatedDate
                FROM    [StreamInternal].[dbo].[v_Contract_FPS] f

	
    END








GO


