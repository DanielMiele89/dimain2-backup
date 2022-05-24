CREATE TABLE [MI].[MRR_Staging_Customer_Temp_NonCore] (
    [ID]                      INT           IDENTITY (1, 1) NOT NULL,
    [FanID]                   INT           NOT NULL,
    [ProgramID]               INT           NOT NULL,
    [PartnerID]               INT           NOT NULL,
    [ClientServicesRef]       NVARCHAR (30) NOT NULL,
    [CumulativeTypeID]        INT           NOT NULL,
    [PeriodTypeID]            INT           NOT NULL,
    [DateID]                  INT           NOT NULL,
    [StartDate]               DATETIME      NOT NULL,
    [EndDate]                 DATETIME      NOT NULL,
    [CustomerAttributeID_0]   INT           NULL,
    [CustomerAttributeID_0BP] INT           NULL,
    [CustomerAttributeID_1]   INT           NULL,
    [CustomerAttributeID_1BP] INT           NULL,
    [CustomerAttributeID_2]   INT           NULL,
    [CustomerAttributeID_2BP] INT           NULL,
    [CustomerAttributeID_3]   INT           NULL,
    CONSTRAINT [PK_MI_MRR_Staging_Customer_Temp_NonCore] PRIMARY KEY CLUSTERED ([ID] ASC)
);

