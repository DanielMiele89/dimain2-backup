CREATE TABLE [Lion].[ArchivedHardBounceEvents_20190213] (
    [Fanid] INT  NOT NULL,
    [Date]  DATE NOT NULL
);


GO
GRANT INSERT
    ON OBJECT::[Lion].[ArchivedHardBounceEvents_20190213] TO [gas]
    AS [dbo];

