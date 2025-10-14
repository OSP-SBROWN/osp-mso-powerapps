CREATE EXTERNAL DATA SOURCE [PerfmaxBlobSource]
    WITH (
    TYPE = BLOB_STORAGE,
    LOCATION = N'https://009storage.blob.core.windows.net',
    CREDENTIAL = [PerfmaxCredential]
    );


GO

