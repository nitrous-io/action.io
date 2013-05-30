AIO.IdeTourView = AIO.TourView.extend
  steps: [
    {
      target: '#ide_main_menu_view'
      content: 'Welcome to the Web IDE for your box. Simple keyboard shortcuts are listed to the right of each menu item.'
      placement: 'bottom'
    },
    {
      target: '#ide_sidebar_view'
      content: 'This is the file directory browser for your box. You can browse the file system, create and remote files, etc...'
      placement: 'right'
    },
    {
      target: '#ide_console_view'
      content: "This is a full linux shell for your box. Try typing any regular linux command and you'll see you can work with your box directly from the command line! Click the icon on the far right of the console to expand to fullscreen."
      placement: 'top'
    }
  ]
