// Point d'entree du binaire Linux : cree l'application GTK puis lui passe la main.
#include "my_application.h"

int main(int argc, char** argv) {
  g_autoptr(MyApplication) app = my_application_new();
  return g_application_run(G_APPLICATION(app), argc, argv);
}
