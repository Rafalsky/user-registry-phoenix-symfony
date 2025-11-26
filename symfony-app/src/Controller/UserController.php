<?php

namespace App\Controller;

use App\Form\UserType;
use App\Service\UserApiClient;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use Symfony\Component\Form\Extension\Core\Type\DateType;
use Symfony\Component\Form\Extension\Core\Type\SubmitType;
use Symfony\Component\Form\Extension\Core\Type\TextType;
use Symfony\Component\Form\FormError;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;
use Symfony\Contracts\HttpClient\Exception\ClientExceptionInterface;

class UserController extends AbstractController
{
    public function __construct(private UserApiClient $userApiClient)
    {
    }

    #[Route('/users', name: 'user_index', methods: ['GET'])]
    public function index(Request $request): Response
    {
        // Build filter form
        $form = $this->createFormBuilder(null, ['method' => 'GET', 'csrf_protection' => false])
            ->add('first_name', TextType::class, ['required' => false])
            ->add('last_name', TextType::class, ['required' => false])
            ->add('gender', ChoiceType::class, [
                'choices' => ['Male' => 'male', 'Female' => 'female'],
                'required' => false,
                'placeholder' => 'All',
            ])
            ->add('birthdate_from', DateType::class, [
                'widget' => 'single_text',
                'required' => false,
                'input' => 'string',
            ])
            ->add('birthdate_to', DateType::class, [
                'widget' => 'single_text',
                'required' => false,
                'input' => 'string',
            ])
            ->add('filter', SubmitType::class, ['label' => 'Filter'])
            ->getForm();

        $form->handleRequest($request);

        // Get filter data from form (this properly extracts values without the 'form' wrapper)
        $formData = $form->getData() ?? [];

        // Merge with query params for sort/pagination
        $queryParams = $request->query->all();

        // Clean up empty filters and merge with sort/pagination params
        $params = array_filter($formData, fn($v) => $v !== '' && $v !== null);

        // Add sort and pagination from query params if present
        if (isset($queryParams['sort'])) {
            $params['sort'] = $queryParams['sort'];
        }
        if (isset($queryParams['direction'])) {
            $params['direction'] = $queryParams['direction'];
        }
        if (isset($queryParams['page'])) {
            $params['page'] = $queryParams['page'];
        }

        // Default sort
        if (!isset($params['sort'])) {
            $params['sort'] = 'id';
            $params['direction'] = 'asc';
        }

        try {
            $result = $this->userApiClient->getUsers($params);
        } catch (\Exception $e) {
            $this->addFlash('error', 'Could not fetch users: ' . $e->getMessage());
            $result = ['data' => [], 'meta' => ['total_count' => 0, 'page' => 1, 'page_size' => 10]];
        }

        return $this->render('user/index.html.twig', [
            'users' => $result['data'],
            'meta' => $result['meta'],
            'form' => $form->createView(),
            'current_filters' => $params,
        ]);
    }

    #[Route('/users/new', name: 'user_new', methods: ['GET', 'POST'])]
    public function new(Request $request): Response
    {
        $form = $this->createForm(UserType::class);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            try {
                $this->userApiClient->createUser($form->getData());
                $this->addFlash('success', 'User created successfully.');
                return $this->redirectToRoute('user_index');
            } catch (ClientExceptionInterface $e) {
                $this->handleApiErrors($e, $form);
            } catch (\Exception $e) {
                $this->addFlash('error', 'Error creating user: ' . $e->getMessage());
            }
        }

        return $this->render('user/new.html.twig', [
            'form' => $form->createView(),
        ]);
    }

    #[Route('/users/{id}/edit', name: 'user_edit', methods: ['GET', 'POST'])]
    public function edit(Request $request, int $id): Response
    {
        try {
            $user = $this->userApiClient->getUser($id);
        } catch (\Exception $e) {
            $this->addFlash('error', 'User not found.');
            return $this->redirectToRoute('user_index');
        }

        $form = $this->createForm(UserType::class, $user);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            try {
                $this->userApiClient->updateUser($id, $form->getData());
                $this->addFlash('success', 'User updated successfully.');
                return $this->redirectToRoute('user_index');
            } catch (ClientExceptionInterface $e) {
                $this->handleApiErrors($e, $form);
            } catch (\Exception $e) {
                $this->addFlash('error', 'Error updating user: ' . $e->getMessage());
            }
        }

        return $this->render('user/edit.html.twig', [
            'form' => $form->createView(),
            'user' => $user,
        ]);
    }

    #[Route('/users/import', name: 'user_import', methods: ['POST'])]
    public function import(Request $request): Response
    {
        if ($this->isCsrfTokenValid('import', $request->request->get('_token'))) {
            try {
                // Call Phoenix API import endpoint
                $response = $this->userApiClient->importUsers();
                $this->addFlash('success', $response['message'] ?? 'Users imported successfully.');
            } catch (\Exception $e) {
                $this->addFlash('error', 'Error importing users: ' . $e->getMessage());
            }
        }

        return $this->redirectToRoute('user_index');
    }

    #[Route('/users/{id}/delete', name: 'user_delete', methods: ['POST'])]
    public function delete(Request $request, int $id): Response
    {
        if ($this->isCsrfTokenValid('delete' . $id, $request->request->get('_token'))) {
            try {
                $this->userApiClient->deleteUser($id);
                $this->addFlash('success', 'User deleted successfully.');
            } catch (\Exception $e) {
                $this->addFlash('error', 'Error deleting user: ' . $e->getMessage());
            }
        }

        return $this->redirectToRoute('user_index');
    }

    private function handleApiErrors(ClientExceptionInterface $e, $form): void
    {
        if ($e->getResponse()->getStatusCode() === 422) {
            $content = $e->getResponse()->toArray(false);
            $errors = $content['errors'] ?? [];
            foreach ($errors as $field => $messages) {
                if ($form->has($field)) {
                    foreach ($messages as $message) {
                        $form->get($field)->addError(new FormError($message));
                    }
                } else {
                    $form->addError(new FormError($field . ': ' . implode(', ', $messages)));
                }
            }
        } else {
            $this->addFlash('error', 'API Error: ' . $e->getMessage());
        }
    }
}
