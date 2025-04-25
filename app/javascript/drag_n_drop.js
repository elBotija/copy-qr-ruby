document.addEventListener("DOMContentLoaded", function(event) {
  const imageTempl = document.getElementById('image-template');
  const gallery = document.getElementById('gallery');
  const overlay = document.getElementById('overlay');
  const dropzone = document.getElementById('dropzone');
  const input = document.getElementById('memorial_photos');
  const allowedFileTypes = input.accept.split(',');
  const allowedMaxBytesSize = input.dataset.maxByteSize;
  const allowedMaxFiles = input.dataset.maxAllowedFiles;

  // use to store pre selected files
  let FILES = {};

  const numberToHumanSize = (size_in_bytes) => {
    let humanSize;

    if (size_in_bytes > 1048576)
      humanSize = Math.round(size_in_bytes / 1048576) + "mb"
    else if(size_in_bytes > 1024)
      humanSize = Math.round(size_in_bytes / 1024) + "kb"
    else
      humanSize = size_in_bytes + "b";

    return humanSize;
  }

  // check if file is of type image and prepend the initialied
  // template to the target element
  const addFile = (target, file) => {
    if(!allowedFileTypes.includes(file.type)) {
      alert(`El archivo ${file.name} tiene un formato inválido.`);
      console.log(`Invalid file type detected, skiping file. ${file.name} - ${file.type}`);
      return;
    };

    if(file.size > allowedMaxBytesSize) {
      alert(`El archivo ${file.name} excede el tamaño máximo permitido.`);
      console.log(`Maximum file size exceeded. ${file.name} - ${numberToHumanSize(file.size)}`);
      return;
    }

    if(Object.keys(FILES).length > (allowedMaxFiles - 1)) {
      alert('La cantidad de fotos excede el máximo permitido.');
      return;
    }

    const objectURL = URL.createObjectURL(file);
    const clone = imageTempl.content.cloneNode(true);

    clone.querySelector("h1").textContent = file.name;
    clone.querySelector("li").id = objectURL;
    clone.querySelector(".delete").dataset.target = objectURL;
    clone.querySelector(".size").textContent = numberToHumanSize(file.size)

    Object.assign(clone.querySelector("img"), {
      src: objectURL,
      alt: file.name
    });

    target.append(clone);

    FILES[objectURL] = file;
  }

  // Remove deleted file from FileList
  const removeFileFromFileList = (fileList, filename) => {
    const dataTransfer = new DataTransfer();

    Array.from(fileList).forEach(file => {
      if (file.name != filename) {
        dataTransfer.items.add(file);
      }
    });

    return dataTransfer.files; // Returns a new FileList
  } 

  // click the hidden input of type file if the visible button is clicked
  // and capture the selected files
  input.onchange = (e) => {
    for (const file of e.target.files) {
      addFile(gallery, file);
    }
  };

  // use to check if a file is being dragged
  const hasFiles = ({ dataTransfer: { types = [] } }) =>
    types.indexOf("Files") > -1;

  // use to drag dragenter and dragleave events.
  // this is to know if the outermost parent is dragged over
  // without issues due to drag events on its children
  let counter = 0;

  // reset counter and append file to gallery when file is dropped
  dropzone.ondrop = (e) => {
    e.preventDefault();

    for (const file of e.dataTransfer.files) {
      addFile(gallery, file);
      overlay.classList.remove("draggedover");
      counter = 0;
    }
  }

  // only react to actual files being dragged
  dropzone.ondragenter = (e) => {
    e.preventDefault();

    if (!hasFiles(e)) {
      return;
    }
    ++counter && overlay.classList.add("draggedover");
  }

  dropzone.ondragleave = (e) => {
    1 > --counter && overlay.classList.remove("draggedover");
  }

  dropzone.ondragover = (e) => {
    if (hasFiles(e)) {
      e.preventDefault();
    }
  }

  // event delegation to capture delete events from the preview cards
  gallery.onclick = ({ target }) => {
    if (target.classList.contains("delete")) {
      const objectURL = target.dataset.target;
      const filename = FILES[objectURL].name;
      
      input.files = removeFileFromFileList(input.files, filename);
      // remove preview image
      document.getElementById(objectURL).remove(objectURL);
      // release ObjectURL resource
      URL.revokeObjectURL(objectURL);
      delete FILES[objectURL];
    }
  };
});
