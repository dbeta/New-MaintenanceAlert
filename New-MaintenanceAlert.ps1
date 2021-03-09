
Install-PackageProvider -Name NuGet
# We demand an exact version of RunAsUser because theoretically future versions could be uploaded that were malicious.
# By setting a static version number, we always know we get a version we trust. You may want to go one step further and fork the repo, inspect, and use your fork.
Install-Module RunAsuser -RequiredVersion 2.0
Import-Module RunASuser -RequiredVersion 2.0
Invoke-AsCurrentUser -CacheToDisk -scriptblock {
    $Title = "Maintenance Notification"
    $Message = "System maintenance is being performed tonight. Please save your work & leave your system on. A reboot may occur. If 3 of these are missed, updates will occur the next time the system comes online."
    $ImageSource = "https://dbeta.com/favicon.png"
    $ButtonMessage = "OK"

    # Required to draw the window
    Add-Type -AssemblyName PresentationFramework
    
    # Setup the logo to show next to the text.
    $Image = New-Object System.Windows.Controls.Image
    $Image.Source = $ImageSource
    $Image.Margin = 10
    # I recommend matching the source image resolution, and the height/width defined here. Windows doesn't do a great job of scaling the image.
    $Image.Height = 128
    $Image.Width = 128

    # Setup the main message text.
    $TextBlock = New-Object System.Windows.Controls.TextBlock
    $TextBlock.Text = $Message
    $TextBlock.Padding = 10
    $TextBlock.FontSize = 20
    $TextBlock.VerticalAlignment = "Center"
    $TextBlock.TextWrapping = "Wrap"
    $TextBlock.MaxWidth = "600"
    $TextBlock.Foreground = "White"

    # Combine the two into a "Horizontal" panel. Depending on your logo or styling concerns, you can switch this to "Vertical".
    $Content = New-Object System.Windows.Controls.StackPanel
    $Content.Orientation = "Horizontal"
    $Content.AddChild($Image)
    $Content.AddChild($TextBlock)

    # XML defining the main window.
    [XML]$Xaml = @"
    <Window 
            xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
            xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
            x:Name="Window" Title="" SizeToContent="WidthAndHeight" WindowStartupLocation="CenterScreen" WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True" Background="Transparent" Opacity="1">
        <Window.Resources>
            <Style TargetType="{x:Type Button}">
                <Setter Property="Template">
                    <Setter.Value>
                        <ControlTemplate TargetType="Button">
                            <Border>
                                <Grid Background="{TemplateBinding Background}">
                                    <ContentPresenter />
                                </Grid>
                            </Border>
                        </ControlTemplate>
                    </Setter.Value>
                </Setter>
            </Style>
        </Window.Resources>
        <Border x:Name="MainBorder" Margin="10" CornerRadius="0" BorderThickness="2" BorderBrush="Gray" Padding="0" >
            <Border.Effect>
                <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="20" ShadowDepth="3" Opacity="0.6" />
            </Border.Effect>
            <Border.Triggers>
                <EventTrigger RoutedEvent="Window.Loaded">
                    <BeginStoryboard>
                        <Storyboard>
                            <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="3" Duration="0:0:1" AutoReverse="False" />
                            <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="20" Duration="0:0:1" AutoReverse="False" />
                        </Storyboard>
                    </BeginStoryboard>
                </EventTrigger>
            </Border.Triggers>
            <Grid >
                <Border Name="Mask" CornerRadius="0" Background="Black" />
                <Grid x:Name="Grid" Background="Black">
                    <Grid.OpacityMask>
                        <VisualBrush Visual="{Binding ElementName=Mask}"/>
                    </Grid.OpacityMask>
                    <StackPanel Name="StackPanel" >                   
                        <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="10" FontFamily="Segoe UI" FontSize="14" Foreground="White" FontWeight="Normal" Background="Black" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="Center" BorderThickness="0"/>
                        <DockPanel Name="ContentHost" Margin="0,10,0,10"  >
                        </DockPanel>
                        <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center" >
                        </DockPanel>
                    </StackPanel>
                </Grid>
            </Grid>
        </Border>
    </Window>
"@
    
    # XML Defining the confirm button.
    [XML]$ButtonXaml = @"
    <Button xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="Auto" Height="30" FontFamily="Segui" FontSize="16" Background="Transparent" Foreground="White" BorderThickness="1" Margin="10" Padding="20,0,20,0" HorizontalAlignment="Right" Cursor="Hand"/>
"@
    
    [XML]$ButtonTextXaml = @"
    <TextBlock xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" FontFamily="Segoe UI" FontSize="16" Background="Gray" Foreground="Black" Padding="20,5,20,5" HorizontalAlignment="Center" VerticalAlignment="Center"/>
"@
    # Create the window.
    $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))

    # Create the button
    $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml))
    $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml))
    $ButtonText.Text = $ButtonMessage
    $Button.Content = $ButtonText
    $Button.Add_MouseEnter( { $This.Content.FontSize = "16" })
    $Button.Add_MouseLeave( { $This.Content.FontSize = "16" })
    $Button.Add_Click( { $Window.Close() })
    $Window.FindName('ButtonHost').AddChild($Button)
    $Window.FindName('ContentHost').AddChild($Content)        
    $Window.Add_Loaded( { $This.Activate() })

    # Set the window to be always on top.
    $Window.Topmost = $true
    $null = $window.Dispatcher.InvokeAsync{ $window.ShowDialog() }.Wait()
}