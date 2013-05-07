AIO.IdeImageView = Em.View.extend
  templateName: 'templates/ide/image'
  classNames: ['ide_image_view']

  imageDataURI: (->
    if (imageData = @get 'document.content') && (contentType = @get 'document.contentType')
      "data:#{contentType};base64,#{imageData}"
  ).property 'document.content', 'document.contentType'
