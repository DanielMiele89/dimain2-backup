CREATE TABLE [MI].[MRR_Customer_Working] (
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
    CONSTRAINT [PK_MI_MRR_Customer_Working] PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_MRR_Customer_Working_Cover]
    ON [MI].[MRR_Customer_Working]([PartnerID] ASC, [ClientServicesRef] ASC, [CumulativeTypeID] ASC, [DateID] ASC)
    INCLUDE([FanID], [ProgramID], [CustomerAttributeID_0], [CustomerAttributeID_0BP], [CustomerAttributeID_1], [CustomerAttributeID_1BP], [CustomerAttributeID_2], [CustomerAttributeID_2BP], [CustomerAttributeID_3]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

