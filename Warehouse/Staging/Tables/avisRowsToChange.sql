CREATE TABLE [Staging].[avisRowsToChange] (
    [fileid]     INT NOT NULL,
    [rownum]     INT NOT NULL,
    [brandmidid] INT NULL,
    PRIMARY KEY CLUSTERED ([fileid] ASC, [rownum] ASC)
);


GO
CREATE NONCLUSTERED INDEX [ix_avisRowsToChange_BrandMIDID]
    ON [Staging].[avisRowsToChange]([brandmidid] ASC);

