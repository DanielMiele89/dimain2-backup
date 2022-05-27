CREATE TABLE [Staging].[ROC_Segmentation_Members] (
    [ID]        INT  IDENTITY (1, 1) NOT NULL,
    [FanID]     INT  NOT NULL,
    [SegmentID] INT  NOT NULL,
    [PartnerID] INT  NOT NULL,
    [StartDate] DATE NOT NULL,
    [EndDate]   DATE NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ROC_Segmentation_Members_FanID_PartnerID_DataDate]
    ON [Staging].[ROC_Segmentation_Members]([FanID] ASC, [PartnerID] ASC, [EndDate] ASC) WITH (FILLFACTOR = 80);

