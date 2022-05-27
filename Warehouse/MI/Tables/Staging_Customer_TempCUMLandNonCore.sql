CREATE TABLE [MI].[Staging_Customer_TempCUMLandNonCore] (
    [ID]                      BIGINT        IDENTITY (1, 1) NOT NULL,
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
    PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UN_FANCuml] UNIQUE NONCLUSTERED ([FanID] ASC, [ProgramID] ASC, [PartnerID] ASC, [ClientServicesRef] ASC, [PeriodTypeID] ASC, [DateID] ASC, [CumulativeTypeID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IND_FanIDCumulativeType]
    ON [MI].[Staging_Customer_TempCUMLandNonCore]([FanID] ASC, [CumulativeTypeID] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_Partner]
    ON [MI].[Staging_Customer_TempCUMLandNonCore]([PartnerID] ASC, [ClientServicesRef] ASC);


GO
CREATE NONCLUSTERED INDEX [IND_Date]
    ON [MI].[Staging_Customer_TempCUMLandNonCore]([DateID] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_NCL_Staging_Customer_TempCUMLandNonCore_MemberSales]
    ON [MI].[Staging_Customer_TempCUMLandNonCore]([PartnerID] ASC, [ClientServicesRef] ASC, [CumulativeTypeID] ASC, [DateID] ASC)
    INCLUDE([FanID], [ProgramID], [CustomerAttributeID_0], [CustomerAttributeID_0BP], [CustomerAttributeID_1], [CustomerAttributeID_1BP], [CustomerAttributeID_2], [CustomerAttributeID_2BP], [CustomerAttributeID_3]);

