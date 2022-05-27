CREATE TABLE [InsightArchive].[MorrisonsLaunch_MorrisonsDataHashed_20180529] (
    [ID_Morrisons]                 BIGINT        NULL,
    [FirstNameHashed_Morrisons]    VARCHAR (100) NULL,
    [SurnameHashed_Morrisons]      VARCHAR (100) NULL,
    [AddressLine1Hashed_Morrisons] VARCHAR (100) NULL,
    [PostCodeHashed_Morrisons]     VARCHAR (100) NULL,
    [EmailHashed_Morrisons]        VARCHAR (100) NULL
);


GO
CREATE CLUSTERED INDEX [IDX_MorrisonsLaunch_Morrisons_Email]
    ON [InsightArchive].[MorrisonsLaunch_MorrisonsDataHashed_20180529]([EmailHashed_Morrisons] ASC) WITH (FILLFACTOR = 75, DATA_COMPRESSION = PAGE);

