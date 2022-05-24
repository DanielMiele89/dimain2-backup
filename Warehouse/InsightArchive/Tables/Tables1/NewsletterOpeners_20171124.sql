CREATE TABLE [InsightArchive].[NewsletterOpeners_20171124] (
    [CAMPAGNE_ID] VARCHAR (50)  NULL,
    [EMAIL]       VARCHAR (125) NULL,
    [FANID]       VARCHAR (50)  NULL
);


GO
CREATE CLUSTERED INDEX [cix_NewsletterOpeners_20171124_FanID]
    ON [InsightArchive].[NewsletterOpeners_20171124]([FANID] ASC);

