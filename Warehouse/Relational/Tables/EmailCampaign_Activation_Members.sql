CREATE TABLE [Relational].[EmailCampaign_Activation_Members] (
    [ID]                         INT         IDENTITY (1, 1) NOT NULL,
    [EmailCampaign_ActivationID] INT         NULL,
    [FanID]                      INT         NULL,
    [ClubID]                     INT         NULL,
    [Grp]                        VARCHAR (7) NULL
);

