USE [StreamInternal]
GO

/****** Object:  View [dbo].[v_ISTA_Stream_HUD]    Script Date: 08/26/2014 15:10:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/**********************************************************************************************
==============================================================================================
*********** Notes/Change Log ****************
--============================================================================================
Date					Author								Description
						Eric McCormick						Return Stream (existing customer) detail information from the
															STREAM.dbo.Consumption table.
															Development Notes:	
															This view is to be used by the v_ISTA_Stream_HUD_Summary view.
08/26/2014 				Jide Akintoye						Formatted View



**********************************************************************************************/




CREATE VIEW [dbo].[v_ISTA_Stream_HUD]
AS
    /****** Script for SelectTopNRows command from SSMS  ******/
SELECT  [ConsID] ,
        [MeterID] ,
        [InvoiceID] ,
        [DateFrom] ,
        [DateTo] ,
        [IntervalTime] ,
        [BegRead] ,
        [EndRead] ,
        [EndRead] - [BegRead] AS Consumption ,
        CASE WHEN DATEDIFF(d , [DateFrom] , [DateTo]) > 0
             THEN ( [EndRead] - [BegRead] ) / DATEDIFF(d , [DateFrom] ,
                                                       [DateTo])
             ELSE 0
        END AS DailyAvgConsumption ,
        [SeqNo] ,
        [Status] ,
        [Note] ,
        [Type] ,
        [ReadingMth] ,
        [Source] ,
        [SourceID] ,
        [RequestID] ,
        [Processed] ,
        [ProcessDate] ,
        [DoNotProcess] ,
        [DNPCode] ,
        [FinalFlag] ,
        [IsBeginReadLDCEstimate] ,
        [IsEndReadLDCEstimate] ,
        [CreateDate] ,
        [CreatedByID] ,
        [migr_bill_batch_id] ,
        [Migr_acct_no] ,
        [migr_service_Id] ,
        [migr_division_code] ,
        [migr_meter_number] ,
        [LastModifiedDate] ,
        [ModifiedByID] ,
        [ValidatedFlag] ,
        [ValidatedDate] ,
        [ThermFactor]
FROM    [Stream].[dbo].[Consumption]
WHERE   TYPE = 'Cons'






GO


