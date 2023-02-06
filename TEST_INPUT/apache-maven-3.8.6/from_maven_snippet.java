public class RuntimeInfo
{
    @SuppressWarnings( "checkstyle:constantname" )
    public static final String userHome = System.getProperty( "user.home" );

    @SuppressWarnings( "checkstyle:constantname" )
    public static final File userMavenConfigurationHome = new File( userHome, ".m2" );

    public static final File DEFAULT_USER_SETTINGS_FILE = new File( userMavenConfigurationHome, "settings.xml" );

    private File settings;

    public RuntimeInfo()
    {
        this.settings = DEFAULT_USER_SETTINGS_FILE;
    }

    public RuntimeInfo( File settings )
    {
        this.settings = settings;
    }

    public File getFile()
    {
        return settings;
    }
}
