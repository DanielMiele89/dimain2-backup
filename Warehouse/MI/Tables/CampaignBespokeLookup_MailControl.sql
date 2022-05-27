CREATE TABLE [MI].[CampaignBespokeLookup_MailControl] (
    [ClientServicesRef]           VARCHAR (40)  NULL,
    [BespokeGrp_Control_TopLevel] VARCHAR (400) NOT NULL,
    [BespokeGrp_Mail_TopLevel]    VARCHAR (400) NOT NULL
);


GO
CREATE CLUSTERED INDEX [IND3]
    ON [MI].[CampaignBespokeLookup_MailControl]([ClientServicesRef] ASC);

