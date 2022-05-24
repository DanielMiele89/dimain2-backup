CREATE TABLE [Staging].[ROC_Segmentation_PartnerSettings] (
    [ID]                INT      IDENTITY (1, 1) NOT NULL,
    [PartnerID]         INT      NOT NULL,
    [Existing]          SMALLINT NOT NULL,
    [Lapsed]            SMALLINT NOT NULL,
    [RegisteredAtLeast] SMALLINT NOT NULL,
    [StartDate]         DATE     NOT NULL,
    [EndDate]           DATE     NULL,
    [CtrlGrp]           TINYINT  NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_ROC_Segmentation_PartnerSettings_PID_SD]
    ON [Staging].[ROC_Segmentation_PartnerSettings]([PartnerID] ASC, [StartDate] ASC);

