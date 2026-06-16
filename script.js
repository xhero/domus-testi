document.addEventListener("DOMContentLoaded", () => {
  const poems = document.querySelectorAll(".poem");

  poems.forEach((poem) => {
    const button = poem.querySelector(".toggle-translation");
    const translation = poem.querySelector(".translation");

    button.addEventListener("click", () => {
      const isHidden = translation.hasAttribute("hidden");

      if (isHidden) {
        translation.removeAttribute("hidden");
        button.textContent = "Nascondi traduzione tedesca";
      } else {
        translation.setAttribute("hidden", "");
        button.textContent = "Mostra traduzione tedesca";
      }
    });
  });
});
