CREATE TABLE [Selections].[CampaignSetup_InProgrammeControlGroup] (
    [ID]                     INT        IDENTITY (1, 1) NOT NULL,
    [PartnerID]              INT        NULL,
    [ControlGroupPercentage] FLOAT (53) NULL,
    [StartDate]              DATE       NULL,
    [EndDate]                DATE       NULL
);

