CREATE TABLE [InsightArchive].[Intern_CustomerTable] (
    [FanID]            INT            NOT NULL,
    [CINID]            INT            NOT NULL,
    [ActivatedMonth]   DATE           NULL,
    [DeactivatedMonth] DATE           NULL,
    [Gender]           CHAR (1)       NULL,
    [AgeCurrent]       TINYINT        NULL,
    [AgeBand]          VARCHAR (10)   NOT NULL,
    [SocialClass]      NVARCHAR (255) NOT NULL,
    [CameoCode]        NVARCHAR (103) NOT NULL,
    [CorePrivateSplit] VARCHAR (7)    NOT NULL
);


GO
DENY SELECT
    ON OBJECT::[InsightArchive].[Intern_CustomerTable] TO [New_PIIRemoved]
    AS [dbo];

