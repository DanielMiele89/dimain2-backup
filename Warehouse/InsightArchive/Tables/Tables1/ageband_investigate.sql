CREATE TABLE [InsightArchive].[ageband_investigate] (
    [fanid]           INT          NOT NULL,
    [cinid]           INT          NOT NULL,
    [dob]             DATE         NOT NULL,
    [agecurrent]      INT          NOT NULL,
    [hdi_ageband_AWS] VARCHAR (50) NOT NULL,
    [calc_ageband]    VARCHAR (50) NOT NULL,
    [activateddate]   DATE         NOT NULL,
    [currentlyactive] BIT          NOT NULL,
    PRIMARY KEY CLUSTERED ([fanid] ASC) WITH (FILLFACTOR = 90)
);

